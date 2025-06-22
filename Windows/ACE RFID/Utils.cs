using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Windows.Forms;
using Microsoft.Win32;

namespace ACE_RFID
{
    internal class Utils
    {

        public static string[] GetAllMaterials()
        {
            List<Filament> items = MatDB.GetAllFilaments();
            string[] materials = new string[items.Count];
            for (int i = 0; i < items.Count; i++)
            {
                materials[i] = items[i].FilamentName;
            }
            return materials;
        }

        public static int[] GetTemps(string materialName)
        {
            Filament item = MatDB.GetFilamentByName(materialName);
            if (item != null && !string.IsNullOrEmpty(item.FilamentParam))
            {
                string[] temps = item.FilamentParam.Split('|');
                int[] tempArray = new int[temps.Length];
                for (int i = 0; i < temps.Length; i++)
                {
                    if (int.TryParse(temps[i].Trim(), out int temp))
                    {
                        tempArray[i] = temp;
                    }
                    else
                    {
                        return new int[] { 200, 210, 50, 60 };
                    }
                }
                return tempArray;
            }
            else
            {
                return new int[] { 200, 210, 50, 60 };
            }
        }

        public static byte[] GetSku(string materialName)
        {
            byte[] skuData = new byte[20];
            Filament item = MatDB.GetFilamentByName(materialName);
            if (item != null && !string.IsNullOrEmpty(item.FilamentId))
            {
                byte[] skuBytes = Encoding.UTF8.GetBytes(item.FilamentId);
                int bytesToCopy = Math.Min(skuBytes.Length, skuData.Length);
                Array.Copy(skuBytes, 0, skuData, 0, bytesToCopy);
            }
            return skuData;
        }

        public static byte[] GetBrand(string materialName)
        {
            byte[] brandData = new byte[20];
            Filament item = MatDB.GetFilamentByName(materialName);
            if (item != null && !string.IsNullOrEmpty(item.FilamentVendor))
            {
                byte[] brandBytes = Encoding.UTF8.GetBytes(item.FilamentVendor);
                int bytesToCopy = Math.Min(brandBytes.Length, brandData.Length);
                Array.Copy(brandBytes, 0, brandData, 0, bytesToCopy);
            }
            return brandData;
        }

        public static int GetMaterialLength(String materialWeight)
        {
            switch (materialWeight)
            {
                case "1 KG":
                    return 330;
                case "750 G":
                    return 247;
                case "600 G":
                    return 198;
                case "500 G":
                    return 165;
                case "250 G":
                    return 82;
            }
            return 330;
        }

        public static String GetMaterialWeight(int materialLength)
        {
            switch (materialLength)
            {
                case 330:
                    return "1 KG";
                case 247:
                    return "750 G";
                case 198:
                    return "600 G";
                case 165:
                    return "500 G";
                case 82:
                    return "250 G";
            }
            return "1 KG";
        }

        public static int[] GetDefaultTemps(String materialType)
        {
            switch (materialType)
            {
                case "ABS":
                    return new int[] { 220, 250, 90, 100 };
                case "ASA":
                    return new int[] { 240, 280, 90, 100 };
                case "HIPS":
                    return new int[] { 230, 245, 80, 100 };
                case "PA":
                    return new int[] { 220, 250, 70, 90 };
                case "PA-CF":
                    return new int[] { 260, 280, 80, 100 };
                case "PC":
                    return new int[] { 260, 300, 100, 110 };
                case "PETG":
                    return new int[] { 230, 250, 70, 90 };
                case "PLA":
                    return new int[] { 190, 230, 50, 60 };
                case "PLA+":
                    return new int[] { 210, 230, 45, 60 };
                case "PLA-CF":
                    return new int[] { 210, 240, 45, 65 };
                case "PVA":
                    return new int[] { 215, 225, 45, 60 };
                case "PP":
                    return new int[] { 225, 245, 80, 105 };
                case "TPU":
                    return new int[] { 210, 230, 25, 60 };
            }
            return new int[] { 185, 300, 45, 110 };
        }

        public static string[] filamentVendors = {
            "3Dgenius",
            "3DJake",
            "3DXTECH",
            "3D BEST-Q",
            "3D Hero",
            "3D-Fuel",
            "Aceaddity",
            "AddNorth",
            "Amazon Basics",
            "AMOLEN",
            "Ankermake",
            "Anycubic",
            "Atomic",
            "AzureFilm",
            "BASF",
            "Bblife",
            "BCN3D",
            "Beyond Plastic",
            "California Filament",
            "Capricorn",
            "CC3D",
            "Colour Dream",
            "colorFabb",
            "Comgrow",
            "Cookiecad",
            "Creality",
            "CERPRiSE",
            "Das Filament",
            "DO3D",
            "DOW",
            "DSM",
            "Duramic",
            "ELEGOO",
            "Eryone",
            "Essentium",
            "eSUN",
            "Extrudr",
            "Fiberforce",
            "Fiberlogy",
            "FilaCube",
            "Filamentive",
            "Fillamentum",
            "FLASHFORGE",
            "Formfutura",
            "Francofil",
            "FilamentOne",
            "Fil X",
            "GEEETECH",
            "Generic",
            "Giantarm",
            "Gizmo Dorks",
            "GreenGate3D",
            "HATCHBOX",
            "Hello3D",
            "IC3D",
            "IEMAI",
            "IIID Max",
            "INLAND",
            "iProspect",
            "iSANMATE",
            "Justmaker",
            "Keene Village Plastics",
            "Kexcelled",
            "LDO",
            "MakerBot",
            "MatterHackers",
            "MIKA3D",
            "NinjaTek",
            "Nobufil",
            "Novamaker",
            "OVERTURE",
            "OVVNYXE",
            "Polymaker",
            "Priline",
            "Printed Solid",
            "Protopasta",
            "Prusament",
            "Push Plastic",
            "R3D",
            "Re-pet3D",
            "Recreus",
            "Regen",
            "Sain SMART",
            "SliceWorx",
            "Snapmaker",
            "SnoLabs",
            "Spectrum",
            "SUNLU",
            "TTYT3D",
            "Tianse",
            "UltiMaker",
            "Valment",
            "Verbatim",
            "VO3D",
            "Voxelab",
            "VOXELPLA",
            "YOOPAI",
            "Yousu",
            "Ziro",
            "Zyltech"};

        public static string[] filamentTypes = {
            "ABS",
            "ASA",
            "HIPS",
            "PA",
            "PA-CF",
            "PC",
            "PLA",
            "PLA-CF",
            "PVA",
            "PP",
            "TPU",
            "PETG",
            "BVOH",
            "PET-CF",
            "PETG-CF",
            "PA6-CF",
            "PAHT-CF",
            "PPS",
            "PPS-CF",
            "PET",
            "ASA-CF",
            "PA-GF",
            "PETG-GF",
            "PP-CF",
            "PCTG"};

        public static byte[] RevArray(byte[] array)
        {
            Array.Reverse(array);
            return array;
        }

        public static int ParseNumber(byte[] byteArray)
        {
            int result = 0;
            foreach (byte b in RevArray(byteArray))
            {
                result = (result << 8) | (b & 0xFF);
            }
            return result;
        }

        public static byte[] NumToBytes(int value)
        {
            return RevArray(new byte[] { (byte)(value >> 8), (byte)value });
        }

        public static byte[] ParseColor(string hexString)
        {
            int length = hexString.Length;
            byte[] byteArray = new byte[length / 2];
            for (int i = 0; i < length; i += 2)
            {
                try
                {
                    byteArray[i / 2] = (byte)Convert.ToByte(hexString.Substring(i, 2), 16);
                }
                catch (Exception)
                {
                    return new byte[] { 0xFF, 0xFF, 0x00, 0x00 };
                }
            }
            return RevArray(byteArray);
        }

        public static string ParseColor(byte[] byteArray)
        {
            try
            {
                StringBuilder hexString = new StringBuilder();
                foreach (byte b in RevArray(byteArray))
                {
                    hexString.Append(b.ToString("x2"));
                }
                return hexString.ToString();
            }
            catch (Exception)
            {
                return "0000FF";
            }
        }

        public static byte[] SubArray(byte[] source, int startIndex, int length)
        {
            if (source == null)
            {
                return null;
            }

            int sourceLength = source.Length;
            if (startIndex < 0 || startIndex >= sourceLength || length <= 0)
            {
                return Array.Empty<byte>();
            }

            int endIndex = Math.Min(startIndex + length, sourceLength);
            int actualLength = endIndex - startIndex;
            byte[] result = new byte[actualLength];
            Array.Copy(source, startIndex, result, 0, actualLength);
            return result;
        }

        public static bool ArrayContains(string[] array, string str)
        {
            if (array == null || str == null)
            {
                return false;
            }
            return array.Any(s => s != null && s.Contains(str.Trim()));
        }

        public static void SetTypeByItem(ComboBox comboBox, string itemName)
        {
            for (int i = 0; i < comboBox.Items.Count; i++)
            {
                if (itemName.Contains(" " + comboBox.Items[i].ToString() + " "))
                {
                    comboBox.SelectedIndex = i;
                    return;
                }
            }
        }

        public static string ReaderVersion(Reader reader)
        {
            try
            {
                return Encoding.ASCII.GetString(reader.GetFirmwareVersion());
            }
            catch { return string.Empty; }
        }

        public static void SaveSetting(string keyName, bool value)
        {
            try
            {
                using (RegistryKey key = Registry.CurrentUser.CreateSubKey("ACE RFID\\Settings"))
                {
                    key?.SetValue(keyName, value ? 1 : 0, RegistryValueKind.DWord);
                }
            }
            catch (Exception){}
        }

        public static bool GetSetting(string keyName, bool defaultValue = false)
        {
            try
            {
                using (RegistryKey key = Registry.CurrentUser.OpenSubKey("ACE RFID\\Settings"))
                {
                    if (key != null)
                    {
                        object value = key.GetValue(keyName);
                        if (value != null && value is int intValue)
                        {
                            return intValue != 0;
                        }
                    }
                    return defaultValue;
                }
            }
            catch (Exception)
            {
                return defaultValue; 
            }
        }

    }
}
