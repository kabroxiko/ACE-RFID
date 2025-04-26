package dngsoftware.acerfid;

import static java.lang.String.format;
import dngsoftware.acerfid.databinding.ActivityMainBinding;
import dngsoftware.acerfid.databinding.AddDialogBinding;
import dngsoftware.acerfid.databinding.PickerDialogBinding;
import static dngsoftware.acerfid.Utils.GetBrand;
import static dngsoftware.acerfid.Utils.GetDefaultTemps;
import static dngsoftware.acerfid.Utils.GetMaterialLength;
import static dngsoftware.acerfid.Utils.GetMaterialWeight;
import static dngsoftware.acerfid.Utils.GetSku;
import static dngsoftware.acerfid.Utils.GetTemps;
import static dngsoftware.acerfid.Utils.SetPermissions;
import static dngsoftware.acerfid.Utils.arrayContains;
import static dngsoftware.acerfid.Utils.bytesToHex;
import static dngsoftware.acerfid.Utils.dp2Px;
import static dngsoftware.acerfid.Utils.filamentTypes;
import static dngsoftware.acerfid.Utils.filamentVendors;
import static dngsoftware.acerfid.Utils.getAllMaterials;
import static dngsoftware.acerfid.Utils.getPixelColor;
import static dngsoftware.acerfid.Utils.materialWeights;
import static dngsoftware.acerfid.Utils.numToBytes;
import static dngsoftware.acerfid.Utils.GetSetting;
import static dngsoftware.acerfid.Utils.SaveSetting;
import static dngsoftware.acerfid.Utils.openUrl;
import static dngsoftware.acerfid.Utils.parseColor;
import static dngsoftware.acerfid.Utils.parseNumber;
import static dngsoftware.acerfid.Utils.playBeep;
import static dngsoftware.acerfid.Utils.populateDatabase;
import static dngsoftware.acerfid.Utils.setTypeByItem;
import static dngsoftware.acerfid.Utils.setVendorByItem;
import static dngsoftware.acerfid.Utils.subArray;
import android.annotation.SuppressLint;
import android.app.Dialog;
import android.content.Context;
import android.content.Intent;
import android.content.res.Configuration;
import android.content.res.Resources;
import android.graphics.Color;
import android.graphics.LinearGradient;
import android.graphics.Shader;
import android.graphics.drawable.ShapeDrawable;
import android.graphics.drawable.shapes.RectShape;
import android.nfc.NfcAdapter;
import android.nfc.Tag;
import android.nfc.tech.NfcA;
import android.os.Bundle;
import android.provider.Settings;
import android.util.DisplayMetrics;
import android.view.MotionEvent;
import android.view.View;
import androidx.annotation.NonNull;
import androidx.appcompat.app.AlertDialog;
import androidx.appcompat.app.AppCompatActivity;
import androidx.room.Room;
import android.view.Window;
import android.view.inputmethod.InputMethodManager;
import android.widget.AdapterView;
import android.widget.ArrayAdapter;
import android.widget.SeekBar;
import android.widget.Toast;
import java.nio.ByteBuffer;
import java.nio.charset.StandardCharsets;
import java.util.Arrays;
import java.util.Locale;
import java.util.Objects;

public class MainActivity extends AppCompatActivity implements NfcAdapter.ReaderCallback {
    private MatDB matDb;
    private NfcAdapter nfcAdapter;
    Tag currentTag = null;
    ArrayAdapter<String> madapter, sadapter;
    String MaterialName, MaterialWeight = "1 KG", MaterialColor = "0000FF";
    Dialog pickerDialog, addDialog;
    int SelectedSize;
    boolean userSelect = false;
    private ActivityMainBinding main;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        Resources res = getApplicationContext().getResources();
        Locale locale = new Locale("en");
        Locale.setDefault(locale);
        Configuration config = new Configuration();
        config.locale = locale;
        res.updateConfiguration(config, res.getDisplayMetrics());

        main = ActivityMainBinding.inflate(getLayoutInflater());
        View rv = main.getRoot();
        setContentView(rv);

        main.editbutton.setVisibility(View.INVISIBLE);
        main.deletebutton.setVisibility(View.INVISIBLE);

        main.colorview.setOnClickListener(view -> openPicker());
        main.colorview.setBackgroundColor(Color.argb(255, 0, 0, 255));
        main.readbutton.setOnClickListener(view -> readTag(currentTag));
        main.writebutton.setOnClickListener(view -> writeTag(currentTag));

        main.addbutton.setOnClickListener(view -> openAddDialog(false));
        main.editbutton.setOnClickListener(view -> openAddDialog(true));

        main.deletebutton.setOnClickListener(view -> {
            AlertDialog.Builder builder = new AlertDialog.Builder(this);
            builder.setTitle(R.string.delete_filament);
            builder.setMessage(MaterialName);
            builder.setPositiveButton(R.string.delete, (dialog, which) -> {
                if (matDb.getFilamentByName(MaterialName) != null) {
                    matDb.deleteItem(matDb.getFilamentByName(MaterialName));
                    loadMaterials(false);
                    dialog.dismiss();
                }
            });
            builder.setNegativeButton(R.string.cancel, (dialog, which) -> dialog.dismiss());
            AlertDialog alert = builder.create();
            alert.show();
        });

        filamentDB rdb = Room.databaseBuilder(this, filamentDB.class, "filament_database")
                .fallbackToDestructiveMigration()
                .allowMainThreadQueries()
                .build();
        matDb = rdb.matDB();

        if (matDb.getItemCount() == 0) {
            populateDatabase(matDb);
        }

        SetPermissions(this);

        try {
            nfcAdapter = NfcAdapter.getDefaultAdapter(this);
            if (nfcAdapter != null && nfcAdapter.isEnabled()) {
                Bundle options = new Bundle();
                options.putInt(NfcAdapter.EXTRA_READER_PRESENCE_CHECK_DELAY, 250);
                nfcAdapter.enableReaderMode(this, this, NfcAdapter.FLAG_READER_NFC_A, options);
            } else {
                Toast.makeText(getApplicationContext(), R.string.please_activate_nfc, Toast.LENGTH_LONG).show();
                startActivity(new Intent(Settings.ACTION_WIRELESS_SETTINGS));
                finish();
            }
        } catch (Exception ignored) {
        }

        sadapter = new ArrayAdapter<>(this, R.layout.spinner_item, materialWeights);
        main.spoolsize.setAdapter(sadapter);
        main.spoolsize.setSelection(SelectedSize);
        main.spoolsize.setOnItemSelectedListener(new AdapterView.OnItemSelectedListener() {
            @Override
            public void onItemSelected(AdapterView<?> parentView, View selectedItemView, int position, long id) {
                SelectedSize = main.spoolsize.getSelectedItemPosition();
                MaterialWeight = sadapter.getItem(position);
            }

            @Override
            public void onNothingSelected(AdapterView<?> parentView) {
            }
        });

        loadMaterials(false);

        main.colorspin.setOnTouchListener((v, event) -> {
            switch (event.getAction()) {
                case MotionEvent.ACTION_DOWN:
                    openPicker();
                    break;
                case MotionEvent.ACTION_UP:
                    v.performClick();
                    break;
                default:
                    break;
            }
            return false;
        });

        main.autoread.setChecked(GetSetting(this, "autoread", false));
        main.autoread.setOnCheckedChangeListener((buttonView, isChecked) -> SaveSetting(this, "autoread", isChecked));

        ReadTagUID(getIntent());
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        if (nfcAdapter != null && nfcAdapter.isEnabled()) {
            try {
                nfcAdapter.disableReaderMode(this);
            } catch (Exception ignored) {
            }
        }
    }

    @Override
    public void onConfigurationChanged(@NonNull Configuration newConfig) {
        super.onConfigurationChanged(newConfig);
        if (pickerDialog != null && pickerDialog.isShowing()) {
            pickerDialog.dismiss();
            openPicker();
        }
    }

    @Override
    public void onTagDiscovered(Tag tag) {
        try {
            currentTag = tag;
            runOnUiThread(() -> {
                Toast.makeText(getApplicationContext(), getString(R.string.tag_found) + bytesToHex(currentTag.getId(), false), Toast.LENGTH_SHORT).show();
                main.tagid.setText(bytesToHex(currentTag.getId(), true));
                if (GetSetting(this, "autoread", false)) {
                    readTag(currentTag);
                }
            });
        } catch (Exception ignored) {
        }
    }

    void loadMaterials(boolean select)
    {
        madapter = new ArrayAdapter<>(this, R.layout.spinner_item, getAllMaterials(matDb));
        main.material.setAdapter(madapter);
        main.material.setOnItemSelectedListener(new AdapterView.OnItemSelectedListener() {
            @Override
            public void onItemSelected(AdapterView<?> parentView, View selectedItemView, int position, long id) {
                MaterialName = madapter.getItem(position);
                assert MaterialName != null;
                main.infotext.setText(String.format(Locale.getDefault(), getString(R.string.info_temps),
                        GetTemps(matDb, MaterialName)[0], GetTemps(matDb, MaterialName)[1], GetTemps(matDb, MaterialName)[2], GetTemps(matDb, MaterialName)[3]));

                if (position <= 11){
                    main.editbutton.setVisibility(View.INVISIBLE);
                    main.deletebutton.setVisibility(View.INVISIBLE);
                }else {
                    main.editbutton.setVisibility(View.VISIBLE);
                    main.deletebutton.setVisibility(View.VISIBLE);
                }

            }
            @Override
            public void onNothingSelected(AdapterView<?> parentView) {
            }
        });
        if (select) {
            main.material.setSelection(madapter.getPosition(MaterialName));
        }
        else {
            main.material.setSelection(3);
        }
    }

    void ReadTagUID(Intent intent) {
        if (intent != null) {
            try {
                if (NfcAdapter.ACTION_TECH_DISCOVERED.equals(intent.getAction()) || NfcAdapter.ACTION_TAG_DISCOVERED.equals(intent.getAction())) {
                    currentTag = intent.getParcelableExtra(NfcAdapter.EXTRA_TAG);
                    assert currentTag != null;
                    Toast.makeText(getApplicationContext(), getString(R.string.tag_found) + bytesToHex(currentTag.getId(), false), Toast.LENGTH_SHORT).show();
                    main.tagid.setText(bytesToHex(currentTag.getId(), true));
                    if (GetSetting(this, "autoread", false)) {
                        readTag(currentTag);
                    }
                }
            } catch (Exception ignored) {
            }
        }
    }

    private void readTag(Tag tag) {
        if (tag == null) {
            Toast.makeText(getApplicationContext(), R.string.no_nfc_tag_found, Toast.LENGTH_SHORT).show();
            return;
        }
        NfcA nfcA = NfcA.get(tag);
        if (nfcA != null) {
            try {
                nfcA.connect();
                byte[] data = new byte[144];
                ByteBuffer buff = ByteBuffer.wrap(data);
                for (int page = 4; page <= 36; page += 4) {
                    byte[] pageData = nfcA.transceive(new byte[] {(byte) 0x30, (byte)page});
                    if (pageData != null) {
                        buff.put(pageData);
                    }
                }
                if (buff.array()[0] != (byte) 0x00) {
                    userSelect = true;
                    MaterialName = new String(subArray(buff.array(), 44, 16), StandardCharsets.UTF_8).trim();
                    main.material.setSelection(madapter.getPosition(MaterialName));
                    MaterialColor = parseColor(subArray(buff.array(), 65, 3));
                    main.colorview.setBackgroundColor(Color.parseColor("#" + MaterialColor));
                    // String sku = new String(subArray(buff.array(), 4, 16), StandardCharsets.UTF_8 ).trim();
                    // String Brand = new String(subArray(buff.array(), 24, 16), StandardCharsets.UTF_8).trim();
                    int extMin = parseNumber(subArray(buff.array(), 80, 2));
                    int extMax = parseNumber(subArray(buff.array(), 82, 2));
                    int bedMin = parseNumber(subArray(buff.array(), 100, 2));
                    int bedMax = parseNumber(subArray(buff.array(), 102, 2));
                    main.infotext.setText(String.format(Locale.getDefault(), getString(R.string.info_temps), extMin, extMax, bedMin, bedMax));
                    // int diameter = parseNumber(subArray(buff.array(),104,2));
                    MaterialWeight = GetMaterialWeight(parseNumber(subArray(buff.array(), 106, 2)));
                    main.spoolsize.setSelection(sadapter.getPosition(MaterialWeight));
                    Toast.makeText(getApplicationContext(), R.string.data_read_from_tag, Toast.LENGTH_SHORT).show();
                    userSelect = false;
                } else {
                    Toast.makeText(getApplicationContext(), R.string.unknown_or_empty_tag, Toast.LENGTH_SHORT).show();
                }
            } catch (Exception ignored) {
                Toast.makeText(getApplicationContext(), R.string.error_reading_tag, Toast.LENGTH_SHORT).show();
            } finally {
                try {
                    nfcA.close();
                } catch (Exception ignored) {
                }
            }
        } else {
            Toast.makeText(getApplicationContext(), R.string.invalid_tag_type, Toast.LENGTH_SHORT).show();
        }
    }

    private void nfcAWritePage(NfcA nfcA, int page, byte[] data) throws Exception {
        byte[] cmd = new byte[6];
        cmd[0] = (byte) 0xA2;
        cmd[1] = (byte) page;
        System.arraycopy(data, 0, cmd, 2, data.length);
        nfcA.transceive(cmd);
    }

    private void writeTag(Tag tag) {
        if (tag == null) {
            Toast.makeText(getApplicationContext(), R.string.no_nfc_tag_found, Toast.LENGTH_SHORT).show();
            return;
        }
        NfcA nfcA = NfcA.get(tag);
        if (nfcA != null) {
            try {
                nfcA.connect();
                nfcAWritePage(nfcA, 4, new byte[]{123, 0, 101, 0});
                for (int i = 0; i < 5; i++) { //sku
                    nfcAWritePage(nfcA, 5 + i, subArray(GetSku(matDb, MaterialName), i * 4, 4));
                }
                for (int i = 0; i < 5; i++) { //brand
                    nfcAWritePage(nfcA, 10 + i, subArray(GetBrand(matDb, MaterialName), i * 4, 4));
                }
                byte[] matData = new byte[20];
                Arrays.fill(matData, (byte) 0);
                System.arraycopy(MaterialName.getBytes(), 0, matData, 0, Math.min(20, MaterialName.length()));
                nfcAWritePage(nfcA, 15, subArray(matData, 0, 4));   //type
                nfcAWritePage(nfcA, 16, subArray(matData, 4, 4));   //type
                nfcAWritePage(nfcA, 17, subArray(matData, 8, 4));   //type
                nfcAWritePage(nfcA, 18, subArray(matData, 12, 4));  //type
                nfcAWritePage(nfcA, 20, parseColor(MaterialColor + "FF")); //color
                //ultralight.writePage(23, new byte[] {50, 0, 100, 0});   //more temps?
                byte[] extTemp = new byte[4];
                System.arraycopy(numToBytes(GetTemps(matDb, MaterialName)[0]), 0, extTemp, 0, 2); //min
                System.arraycopy(numToBytes(GetTemps(matDb, MaterialName)[1]), 0, extTemp, 2, 2); //max
                nfcAWritePage(nfcA, 24, extTemp);
                byte[] bedTemp = new byte[4];
                System.arraycopy(numToBytes(GetTemps(matDb, MaterialName)[2]), 0, bedTemp, 0, 2); //min
                System.arraycopy(numToBytes(GetTemps(matDb, MaterialName)[3]), 0, bedTemp, 2, 2); //max
                nfcAWritePage(nfcA, 29, bedTemp);
                byte[] filData = new byte[4];
                System.arraycopy(numToBytes(175), 0, filData, 0, 2); //diameter
                System.arraycopy(numToBytes(GetMaterialLength(MaterialWeight)), 0, filData, 2, 2); //length
                nfcAWritePage(nfcA, 30, filData);
                nfcAWritePage(nfcA, 31, new byte[]{(byte) 232, 3, 0, 0}); //?
                playBeep();
                Toast.makeText(getApplicationContext(), R.string.data_written_to_tag, Toast.LENGTH_SHORT).show();
            } catch (Exception ignored) {
                Toast.makeText(getApplicationContext(), R.string.error_writing_to_tag, Toast.LENGTH_SHORT).show();
            } finally {
                try {
                    nfcA.close();
                } catch (Exception ignored) {
                }
            }
        } else {
            Toast.makeText(getApplicationContext(), R.string.invalid_tag_type, Toast.LENGTH_SHORT).show();
        }
    }

    @SuppressLint("ClickableViewAccessibility")
    void openPicker() {
        try {
            pickerDialog = new Dialog(this, R.style.Theme_AceRFID);
            pickerDialog.requestWindowFeature(Window.FEATURE_NO_TITLE);
            pickerDialog.setCanceledOnTouchOutside(false);
            pickerDialog.setTitle(R.string.pick_color);
            PickerDialogBinding dl = PickerDialogBinding.inflate(getLayoutInflater());
            View rv = dl.getRoot();
            pickerDialog.setContentView(rv);

            dl.dcolorview.setBackgroundColor(Color.parseColor("#" + MaterialColor));
            dl.txtcolor.setText(MaterialColor);
            dl.btncls.setOnClickListener(v -> {
                if (dl.txtcolor.getText().toString().length() == 6) {
                    try {
                        MaterialColor = dl.txtcolor.getText().toString();
                        main.colorview.setBackgroundColor(Color.parseColor("#" + MaterialColor));
                        dl.dcolorview.setBackgroundColor(Color.parseColor("#" + MaterialColor));
                    } catch (Exception ignored) {
                    }
                }
                pickerDialog.dismiss();
            });
            dl.txtcolor.setOnEditorActionListener((v, actionId, event) -> {
                InputMethodManager imm = (InputMethodManager) getSystemService(Context.INPUT_METHOD_SERVICE);
                imm.hideSoftInputFromWindow(dl.txtcolor.getWindowToken(), 0);
                if (dl.txtcolor.getText().toString().length() == 6) {
                    try {
                        MaterialColor = dl.txtcolor.getText().toString();
                        main.colorview.setBackgroundColor(Color.parseColor("#" + MaterialColor));
                        dl.dcolorview.setBackgroundColor(Color.parseColor("#" + MaterialColor));

                    } catch (Exception ignored) {
                    }
                }
                return true;
            });
            dl.picker.setOnTouchListener((v, event) -> {
                final int currPixel = getPixelColor(event, dl.picker);
                if (currPixel != 0) {
                    MaterialColor = format("%02x%02x%02x", Color.red(currPixel), Color.green(currPixel), Color.blue(currPixel)).toUpperCase();
                    main.colorview.setBackgroundColor(Color.argb(255, Color.red(currPixel), Color.green(currPixel), Color.blue(currPixel)));
                    dl.dcolorview.setBackgroundColor(Color.argb(255, Color.red(currPixel), Color.green(currPixel), Color.blue(currPixel)));
                    pickerDialog.dismiss();
                }
                return false;
            });
            DisplayMetrics displayMetrics = new DisplayMetrics();
            getWindowManager().getDefaultDisplay().getMetrics(displayMetrics);
            float scrWwidth = displayMetrics.widthPixels;
            if (scrWwidth > dp2Px(this, 500)) scrWwidth = dp2Px(this, 500);

            LinearGradient test = new LinearGradient(50.f, 0.f, scrWwidth - 250, 0.0f,
                    new int[]{0xFF000000, 0xFF0000FF, 0xFF00FF00, 0xFF00FFFF, 0xFFFF0000, 0xFFFF00FF, 0xFFFFFF00, 0xFFFFFFFF}, null, Shader.TileMode.CLAMP);
            ShapeDrawable shape = new ShapeDrawable(new RectShape());
            shape.getPaint().setShader(test);
            dl.seekbarFont.setProgressDrawable(shape);
            dl.seekbarFont.setMax(256 * 7 - 1);
            dl.seekbarFont.setOnSeekBarChangeListener(new SeekBar.OnSeekBarChangeListener() {
                @Override
                public void onProgressChanged(SeekBar seekBar, int progress, boolean fromUser) {
                    if (fromUser) {
                        int r = 0;
                        int g = 0;
                        int b = 0;

                        if (progress < 256) {
                            b = progress;
                        } else if (progress < 256 * 2) {
                            g = progress % 256;
                            b = 256 - progress % 256;
                        } else if (progress < 256 * 3) {
                            g = 255;
                            b = progress % 256;
                        } else if (progress < 256 * 4) {
                            r = progress % 256;
                            g = 256 - progress % 256;
                            b = 256 - progress % 256;
                        } else if (progress < 256 * 5) {
                            r = 255;
                            b = progress % 256;
                        } else if (progress < 256 * 6) {
                            r = 255;
                            g = progress % 256;
                            b = 256 - progress % 256;
                        } else if (progress < 256 * 7) {
                            r = 255;
                            g = 255;
                            b = progress % 256;
                        }
                        MaterialColor = format("%02x%02x%02x", r, g, b).toUpperCase();
                        dl.txtcolor.setText(MaterialColor);
                        main.colorview.setBackgroundColor(Color.argb(255, r, g, b));
                        dl.dcolorview.setBackgroundColor(Color.argb(255, r, g, b));
                    }
                }

                @Override
                public void onStartTrackingTouch(SeekBar seekBar) {
                }

                @Override
                public void onStopTrackingTouch(SeekBar seekBar) {
                }
            });
            pickerDialog.show();
        } catch (Exception ignored) {
        }
    }

    void openAddDialog(boolean edit) {
        try {

            if (!Utils.GetSetting(this,"CFN",false)) {
                AlertDialog.Builder builder = new AlertDialog.Builder(this);
                builder.setTitle(R.string.notice);
                builder.setMessage(R.string.cf_notice);
                builder.setPositiveButton(R.string.accept, (dialog, which) -> {
                    Utils.SaveSetting(this, "CFN", true);
                    dialog.dismiss();
                    openAddDialog(edit);
                });
                builder.setNegativeButton(R.string.cancel, (dialog, which) -> dialog.dismiss());
                AlertDialog alert = builder.create();
                alert.show();
                return;
            }

            addDialog = new Dialog(this, R.style.Theme_AceRFID);
            addDialog.requestWindowFeature(Window.FEATURE_NO_TITLE);
            addDialog.setCanceledOnTouchOutside(false);
            addDialog.setTitle(R.string.add_filament);
            AddDialogBinding dl = AddDialogBinding.inflate(getLayoutInflater());
            View rv = dl.getRoot();
            addDialog.setContentView(rv);
            dl.btncls.setOnClickListener(v -> addDialog.dismiss());
            dl.btnhlp.setOnClickListener(v -> openUrl(this,getString(R.string.helpurl)));

            dl.chkvendor.setOnClickListener(v -> {
                if (dl.chkvendor.isChecked()) {
                    dl.vendor.setVisibility(View.INVISIBLE);
                    dl.txtvendor.setVisibility(View.VISIBLE);

                } else {
                    dl.vendor.setVisibility(View.VISIBLE);
                    dl.txtvendor.setVisibility(View.INVISIBLE);

                }
            });

            if (edit) {
                dl.btnsave.setText(R.string.save);
                dl.lbltitle.setText(R.string.edit_filament);
            }
            else {
                dl.btnsave.setText(R.string.add);
                dl.lbltitle.setText(R.string.add_filament);
            }

           dl.btnsave.setOnClickListener(v -> {
               if (dl.txtserial.getText().toString().isEmpty() || dl.txtextmin.getText().toString().isEmpty() || dl.txtextmax.getText().toString().isEmpty() || dl.txtbedmin.getText().toString().isEmpty() || dl.txtbedmax.getText().toString().isEmpty()) {
                   Toast.makeText(getApplicationContext(), R.string.fill_all_fields, Toast.LENGTH_SHORT).show();
                   return;
               }
               if (dl.chkvendor.isChecked() && dl.txtvendor.getText().toString().isEmpty()) {
                   Toast.makeText(getApplicationContext(), R.string.fill_all_fields, Toast.LENGTH_SHORT).show();
                   return;
               }

               String vendor = dl.vendor.getSelectedItem().toString();
               if (dl.chkvendor.isChecked())
               {
                   vendor = dl.txtvendor.getText().toString().trim();
               }
               if (edit) {
                   updateFilament(vendor, dl.type.getSelectedItem().toString(), dl.txtserial.getText().toString(), dl.txtextmin.getText().toString(), dl.txtextmax.getText().toString(), dl.txtbedmin.getText().toString(), dl.txtbedmax.getText().toString());
               } else {
                   addFilament(vendor, dl.type.getSelectedItem().toString(), dl.txtserial.getText().toString(), dl.txtextmin.getText().toString(), dl.txtextmax.getText().toString(), dl.txtbedmin.getText().toString(), dl.txtbedmax.getText().toString());
               }

               addDialog.dismiss();
           });

            ArrayAdapter<String> vadapter = new ArrayAdapter<>(this, R.layout.spinner_item, filamentVendors);
            dl.vendor.setAdapter(vadapter);

            ArrayAdapter<String> tadapter = new ArrayAdapter<>(this, R.layout.spinner_item, filamentTypes);
            dl.type.setAdapter(tadapter);

            dl.type.setOnTouchListener((v, event) -> {
                userSelect = true;
                v.performClick();
                return false;
            });

            dl.type.setOnItemSelectedListener(new AdapterView.OnItemSelectedListener() {
                @Override
                public void onItemSelected(AdapterView<?> parentView, View selectedItemView, int position, long id) {
                    if (userSelect) {
                        String tmpType = Objects.requireNonNull(tadapter.getItem(position));
                        int[] temps = GetDefaultTemps(tmpType);
                        dl.txtextmin.setText(String.valueOf(temps[0]));
                        dl.txtextmax.setText(String.valueOf(temps[1]));
                        dl.txtbedmin.setText(String.valueOf(temps[2]));
                        dl.txtbedmax.setText(String.valueOf(temps[3]));
                        userSelect = false;
                    }
                }
                @Override
                public void onNothingSelected(AdapterView<?> parentView) {
                    userSelect = false;
                }
            });

            if (edit) {
                setTypeByItem(dl.type, tadapter, MaterialName);
                try {
                    if (!arrayContains(filamentVendors, MaterialName.split(dl.type.getSelectedItem().toString() + " ")[0].trim())) {
                        dl.chkvendor.setChecked(true);
                        dl.txtvendor.setVisibility(View.VISIBLE);
                        dl.vendor.setVisibility(View.INVISIBLE);
                        dl.txtvendor.setText(MaterialName.split(dl.type.getSelectedItem().toString() + " ")[0].trim());
                    } else {
                        dl.chkvendor.setChecked(false);
                        dl.txtvendor.setVisibility(View.INVISIBLE);
                        dl.vendor.setVisibility(View.VISIBLE);
                        setVendorByItem(dl.vendor, vadapter, MaterialName);
                    }
                } catch (Exception ignored) {
                    dl.chkvendor.setChecked(false);
                    dl.txtvendor.setVisibility(View.INVISIBLE);
                    dl.vendor.setVisibility(View.VISIBLE);
                    dl.vendor.setSelection(0);
                }
                try {
                    dl.txtserial.setText(MaterialName.split(dl.type.getSelectedItem().toString() + " ")[1]);
                } catch (ArrayIndexOutOfBoundsException ignored) {
                    dl.txtserial.setText("");
                }
                int[] temps = GetTemps(matDb, MaterialName);
                dl.txtextmin.setText(String.valueOf(temps[0]));
                dl.txtextmax.setText(String.valueOf(temps[1]));
                dl.txtbedmin.setText(String.valueOf(temps[2]));
                dl.txtbedmax.setText(String.valueOf(temps[3]));

            }else {
                dl.vendor.setSelection(0);
                dl.type.setSelection(7);
                int[] temps = GetDefaultTemps("PLA");
                dl.txtextmin.setText(String.valueOf(temps[0]));
                dl.txtextmax.setText(String.valueOf(temps[1]));
                dl.txtbedmin.setText(String.valueOf(temps[2]));
                dl.txtbedmax.setText(String.valueOf(temps[3]));
            }

            addDialog.show();
        } catch (Exception ignored) {}
    }

    void addFilament(String tmpVendor, String tmpType, String tmpSerial, String tmpExtMin, String tmpExtMax, String tmpBedMin, String tmpBedMax) {
        Filament filament = new Filament();
        filament.position =  matDb.getItemCount();
        filament.filamentID = "";
        filament.filamentName = String.format("%s %s %s", tmpVendor.trim(), tmpType, tmpSerial.trim());
        filament.filamentVendor = "";
        filament.filamentParam = String.format("%s|%s|%s|%s", tmpExtMin, tmpExtMax, tmpBedMin, tmpBedMax);
        matDb.addItem(filament);
        loadMaterials(false);
    }

    void updateFilament(String tmpVendor, String tmpType, String tmpSerial, String tmpExtMin, String tmpExtMax, String tmpBedMin, String tmpBedMax) {
        Filament currentFilament = matDb.getFilamentByName(MaterialName);
        int tmpPosition = currentFilament.position;
        matDb.deleteItem(currentFilament);
        MaterialName = String.format("%s %s %s", tmpVendor.trim(), tmpType, tmpSerial.trim());
        Filament filament = new Filament();
        filament.position =  tmpPosition;
        filament.filamentID = "";
        filament.filamentName = MaterialName;
        filament.filamentVendor = "";
        filament.filamentParam = String.format("%s|%s|%s|%s", tmpExtMin, tmpExtMax, tmpBedMin, tmpBedMax);
        matDb.addItem(filament);
        loadMaterials(true);
    }

}