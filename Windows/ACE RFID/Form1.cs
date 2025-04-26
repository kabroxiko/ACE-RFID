using NfcDevice;
using System;
using System.Drawing;
using System.Media;
using System.Text;
using System.Threading;
using System.Windows.Forms;


namespace ACE_RFID
{
    public partial class Form1 : Form
    {

        private ACR122U acr122u = new ACR122U();
        private PCSC.ICardReader reader;
        private String materialColor;


        public Form1()
        {
            InitializeComponent();
            acr122u.CardInserted += Acr122u_CardInserted;
            acr122u.CardRemoved += Acr122u_CardRemoved;
        }



        private void Form1_Load(object sender, EventArgs e)
        {

            BackColor = ColorTranslator.FromHtml("#F4F4F4");
            lblConnect.BackColor = ColorTranslator.FromHtml("#F4F4F4");
            btnRead.BackColor = ColorTranslator.FromHtml("#1976D2");
            btnWrite.BackColor = ColorTranslator.FromHtml("#1976D2");
            btnSave.BackColor = ColorTranslator.FromHtml("#1976D2");
            btnCls.BackColor = ColorTranslator.FromHtml("#1976D2");

            btnDel.Visible = false;
            btnEdit.Visible = false;

            panel1.Location = new Point(0, 0);
            lblConnect.Location = new Point(0, 0);


            if (MatDB.GetItemCount() == 0)
            {
                MatDB.PopulateDatabase();
            }

            materialType.Items.AddRange(Utils.GetAllMaterials());
            cboType.Items.AddRange(Utils.filamentTypes);
            cboVendor.Items.AddRange(Utils.filamentVendors);

            materialType.Text = "PLA";
            materialWeight.Text = "1 KG";
            materialColor = "0000FF";
            btnColor.BackColor = ColorTranslator.FromHtml("#" + materialColor);

            try
            {
                lblConnect.Visible = false;
                acr122u.Init(true, 144, 4, 4, 200);
            }
            catch (Exception)
            {
                SystemSounds.Beep.Play();
                lblConnect.Visible = true;
            }
        }


        private void Form1_FormClosed(object sender, FormClosedEventArgs e)
        {
            Environment.Exit(0);
        }


        private void Acr122u_CardInserted(PCSC.ICardReader r)
        {
            try
            {
                reader = r;
                Invoke((MethodInvoker)delegate ()
                {
                    lblUid.Text = BitConverter.ToString(acr122u.GetUID(reader)).Replace("-", " ");
                    if (checkBox1.Checked)
                    {
                        ReadTag();
                    }
                });
            }
            catch (Exception e)
            {
                ShowMsg(e.Message);
            }
        }


        private void Acr122u_CardRemoved()
        {
            try
            {
                Invoke((MethodInvoker)delegate ()
                {
                    lblUid.Text = string.Empty;
                });
            }
            catch (Exception e)
            {
                ShowMsg(e.Message);
            }
        }


        void WriteTag()
        {
            try
            {
                if (reader != null && reader.IsConnected)
                {

                    byte[] buffer = new byte[144];

                    new byte[] { 123, 0, 101, 0 }.CopyTo(buffer, 0);

                    Utils.GetSku(materialType.Text).CopyTo(buffer, 4); //sku

                    Utils.GetBrand(materialType.Text).CopyTo(buffer, 24); //brand

                    Encoding.UTF8.GetBytes(materialType.Text).CopyTo(buffer, 44); //type

                    buffer[64] = (byte)0xFF;
                    Utils.ParseColor(materialColor).CopyTo(buffer, 65); //color

                    Utils.NumToBytes(Utils.GetTemps(materialType.Text)[0]).CopyTo(buffer, 80); //ext min
                    Utils.NumToBytes(Utils.GetTemps(materialType.Text)[1]).CopyTo(buffer, 82); //ext max
                    Utils.NumToBytes(Utils.GetTemps(materialType.Text)[2]).CopyTo(buffer, 100); //bed min
                    Utils.NumToBytes(Utils.GetTemps(materialType.Text)[3]).CopyTo(buffer, 102); //bed max

                    Utils.NumToBytes(175).CopyTo(buffer, 104); //diameter
                    Utils.NumToBytes(Utils.GetMaterialLength(materialWeight.Text)).CopyTo(buffer, 106); //length


                    acr122u.WriteData(reader, buffer);

                    ShowMsg("Data written to TAG");
                }
            }
            catch (Exception)
            {
                ShowMsg("Error writing to TAG");
            }
        }


        private void ReadTag()
        {
            try
            {
                if (reader != null && reader.IsConnected)
                {
                    byte[] buffer = acr122u.ReadData(reader);

                    // String sku = Encoding.UTF8.GetString(Utils.SubArray(buffer, 4, 20)).Trim();
                    // String Brand = Encoding.UTF8.GetString(Utils.SubArray(buffer, 24, 20)).Trim();

                    materialType.Text = Encoding.UTF8.GetString(Utils.SubArray(buffer, 44, 20)).Trim();

                    materialColor = Utils.ParseColor(Utils.SubArray(buffer, 65, 3));

                    btnColor.BackColor = ColorTranslator.FromHtml("#" + materialColor);

                    int extMin = Utils.ParseNumber(Utils.SubArray(buffer, 80, 2));
                    int extMax = Utils.ParseNumber(Utils.SubArray(buffer, 82, 2));
                    int bedMin = Utils.ParseNumber(Utils.SubArray(buffer, 100, 2));
                    int bedMax = Utils.ParseNumber(Utils.SubArray(buffer, 102, 2));

                    lblTemps.Text = String.Format("Extruder Temp: {0:d} min | {1:d} max\nBed Temp: {2:d} min | {3:d} max", extMin, extMax, bedMin, bedMax);


                    // int diameter = Utils.ParseNumber(Utils.SubArray(buffer,104,2));
                    materialWeight.Text = Utils.GetMaterialWeight(Utils.ParseNumber(Utils.SubArray(buffer, 106, 2)));

                    ShowMsg("Data read from TAG");
                }
            }
            catch (Exception)
            {
                ShowMsg("Error reading TAG");
            }

        }


        private void ShowMsg(String message)
        {
            Invoke((MethodInvoker)delegate ()
           {
               lblMsg.Text = message;
           });
            System.Threading.Timer timer = new System.Threading.Timer(t =>
            {
                Invoke((MethodInvoker)delegate ()
                {
                    lblMsg.Text = String.Empty;
                });
            }, null, 3000, Timeout.Infinite);
        }


        private void btnRead_Click(object sender, EventArgs e)
        {
            ReadTag();
        }


        private void btnWrite_Click(object sender, EventArgs e)
        {
            WriteTag();
        }


        private void btnColor_Click(object sender, EventArgs e)
        {
            if (colorDialog1.ShowDialog() == DialogResult.OK)
            {
                btnColor.BackColor = colorDialog1.Color;
                materialColor = (colorDialog1.Color.ToArgb() & 0x00FFFFFF).ToString("X6");
            }
        }


        private void lblConnect_Click(object sender, EventArgs e)
        {
            try
            {
                lblConnect.Visible = false;
                acr122u.Init(true, 144, 4, 4, 200);
            }
            catch (Exception)
            {
                SystemSounds.Beep.Play();
                lblConnect.Visible = true;
            }
        }


        private void checkBox2_CheckedChanged(object sender, EventArgs e)
        {
            if (checkBox2.Checked)
            {
                cboVendor.DropDownStyle = ComboBoxStyle.DropDown;
                cboVendor.Text = string.Empty;
            }
            else
            {
                cboVendor.DropDownStyle = ComboBoxStyle.DropDownList;
                cboVendor.Text = cboVendor.Items[cboVendor.SelectedIndex].ToString();
            }
        }


        private void btnAdd_Click(object sender, EventArgs e)
        {
            if (Utils.GetSetting("CFN", false) == false)
            {
                DialogResult result = MessageBox.Show("Custom filament settings do not currently work with remote print or cloud print functions.", "Notice", MessageBoxButtons.OKCancel, MessageBoxIcon.Question);
                if (result == DialogResult.OK)
                {
                    Utils.SaveSetting("CFN", true);
                }
                else
                {
                    return;
                }
            }

            cboType.Text = cboType.Items[0].ToString();
            cboVendor.Text = cboVendor.Items[0].ToString();
            btnSave.Text = "Add";
            panel1.Visible = true;
        }


        private void btnEdit_Click(object sender, EventArgs e)
        {
            if (Utils.GetSetting("CFN", false) == false)
            {
                DialogResult result = MessageBox.Show("Custom filament settings do not currently work with remote print or cloud print functions.", "Notice", MessageBoxButtons.OKCancel, MessageBoxIcon.Question);
                if (result == DialogResult.OK)
                {
                    Utils.SaveSetting("CFN", true);
                }
                else
                {
                    return;
                }
            }

            Filament filament = MatDB.GetFilamentByName(materialType.Text);
            int pos = filament.Position;
            if (pos > 11)
            {
                Utils.SetTypeByItem(cboType, filament.FilamentName);

                String filamentVendor = filament.FilamentName.Split(new string[] { " " + cboType.Text + " " }, StringSplitOptions.None)[0].Trim();

                if (Utils.ArrayContains(Utils.filamentVendors, filamentVendor))
                {
                    checkBox2.Checked = false;
                    cboVendor.DropDownStyle = ComboBoxStyle.DropDownList;
                    cboVendor.Text = filamentVendor;
                }
                else
                {
                    checkBox2.Checked = true;
                    cboVendor.DropDownStyle = ComboBoxStyle.DropDown;
                    cboVendor.Text = filamentVendor;
                }

                txtSerial.Text = filament.FilamentName.Split(new string[] { " " + cboType.Text + " " }, StringSplitOptions.None)[1].Trim();
                txtExtMin.Text = filament.FilamentParam.Split('|')[0];
                txtExtMax.Text = filament.FilamentParam.Split('|')[1];
                txtBedMin.Text = filament.FilamentParam.Split('|')[2];
                txtBedMax.Text = filament.FilamentParam.Split('|')[3];
                btnSave.Text = "Save";
                panel1.Visible = true;
            }
        }


        private void btnDel_Click(object sender, EventArgs e)
        {
            int pos = MatDB.GetFilamentByName(materialType.Text).Position;
            if (pos > 11)
            {
                DialogResult result = MessageBox.Show("Are you sure you want to delete\n\n    " + materialType.Text, "Confirmation", MessageBoxButtons.YesNo, MessageBoxIcon.Question);
                if (result == DialogResult.Yes)
                {
                    MatDB.DeleteFilament(new Filament { Position = pos });
                    materialType.Items.Clear();
                    materialType.Items.AddRange(Utils.GetAllMaterials());
                    materialType.Text = materialType.Items[0].ToString();
                }
            }
        }


        private void btnSave_Click(object sender, EventArgs e)
        {
            if (cboVendor.Text.Equals(String.Empty) || cboType.Text.Equals(String.Empty) ||
                txtSerial.Text.Equals(String.Empty) || txtExtMin.Text.Equals(String.Empty) ||
                txtExtMax.Text.Equals(String.Empty) || txtBedMin.Text.Equals(String.Empty) || txtBedMax.Text.Equals(String.Empty))
            {
                MessageBox.Show("You must fill all fields", "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
                return;
            }

            panel1.Visible = false;

            if (btnSave.Text.Equals("Save"))
            {
                Filament filament = MatDB.GetFilamentByName(materialType.Text);

                filament.FilamentId = "";
                filament.FilamentName = cboVendor.Text.Trim() + " " + cboType.Text.Trim() + " " + txtSerial.Text.Trim();
                filament.FilamentVendor = "";
                filament.FilamentParam = txtExtMin.Text + "|" + txtExtMax.Text + "|" + txtBedMin.Text + "|" + txtBedMax.Text;

                MatDB.UpdateFilament(filament);

                materialType.Items.Clear();
                materialType.Items.AddRange(Utils.GetAllMaterials());
                materialType.Text = materialType.Items[filament.Position].ToString();

            }
            else
            {

                MatDB.AddFilament(new Filament { FilamentId = "", FilamentName = cboVendor.Text.Trim() + " " + cboType.Text.Trim() + " " + txtSerial.Text.Trim(), FilamentVendor = "", FilamentParam = txtExtMin.Text + "|" + txtExtMax.Text + "|" + txtBedMin.Text + "|" + txtBedMax.Text });
                materialType.Items.Clear();
                materialType.Items.AddRange(Utils.GetAllMaterials());
                materialType.Text = materialType.Items[MatDB.GetItemCount() - 1].ToString();
            }

        }


        private void materialType_SelectedIndexChanged(object sender, EventArgs e)
        {
            if (materialType.SelectedIndex > 11)
            {
                btnDel.Visible = true;
                btnEdit.Visible = true;
            }
            else
            {
                btnDel.Visible = false;
                btnEdit.Visible = false;
            }

            Filament filament = MatDB.GetFilamentByName(materialType.Text);
            lblTemps.Text = String.Format("Extruder Temp: {0:d} min | {1:d} max\nBed Temp: {2:d} min | {3:d} max", filament.FilamentParam.Split('|')[0], filament.FilamentParam.Split('|')[1], filament.FilamentParam.Split('|')[2], filament.FilamentParam.Split('|')[3]);
        }


        private void btnCls_Click(object sender, EventArgs e)
        {
            panel1.Visible = false;
        }


        private void cboType_SelectedIndexChanged(object sender, EventArgs e)
        {
            txtExtMin.Text = Utils.GetDefaultTemps(cboType.Text)[0].ToString();
            txtExtMax.Text = Utils.GetDefaultTemps(cboType.Text)[1].ToString();
            txtBedMin.Text = Utils.GetDefaultTemps(cboType.Text)[2].ToString();
            txtBedMax.Text = Utils.GetDefaultTemps(cboType.Text)[3].ToString();
        }


        private void txtExtMin_KeyPress(object sender, KeyPressEventArgs e)
        {
            e.Handled = !char.IsDigit(e.KeyChar) && !char.IsControl(e.KeyChar);
        }


        private void txtExtMax_KeyPress(object sender, KeyPressEventArgs e)
        {
            e.Handled = !char.IsDigit(e.KeyChar) && !char.IsControl(e.KeyChar);
        }


        private void txtBedMin_KeyPress(object sender, KeyPressEventArgs e)
        {
            e.Handled = !char.IsDigit(e.KeyChar) && !char.IsControl(e.KeyChar);
        }


        private void txtBedMax_KeyPress(object sender, KeyPressEventArgs e)
        {
            e.Handled = !char.IsDigit(e.KeyChar) && !char.IsControl(e.KeyChar);
        }
    }
}
