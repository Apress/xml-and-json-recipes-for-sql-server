using System;
using System.Data;
using System.Data.SqlClient;
using System.Data.SqlTypes;
using Microsoft.SqlServer.Server;
using System.IO; 
using System.Collections;

public partial class XMLFileETL
{
    [SqlFunction(Name = "FilesList", FillRowMethodName = "FillRow",
        TableDefinition = "string nvarchar(500)")]
    public static IEnumerable FilesList(SqlString dir, SqlString ext)
    {
        try
        {
            string[] files = Directory.GetFiles(dir.Value, "*." + ext.Value);
            return files;
        }
        catch
        {
            // Return null on error.
            return null;
        }
    }

    [SqlFunction]
    public static SqlString WriteXMLFile(SqlString XMLContent,
        SqlString DirPath,
        SqlString FileName,
        SqlBoolean DateStamp)
    {
        /*  Parameters:
         XMLContent: Contains XML document.
         DirPath: The directory path to write to.
         FileName: The file name.
         DateStamp: Determines add datetime stamp to the file or not.
         */

        try
        {
            string strXMLFile = "";
            // Check input parameters for NULL.
            if (!XMLContent.IsNull &&
                !DirPath.IsNull &&
                !FileName.IsNull)
            {
                // Get the directory information for the specified directory.
                var dir = Path.GetDirectoryName(DirPath.Value);
                // Determine whether the specified directory exists.
                if (!Directory.Exists(dir))
                    // Create the directories if is missing.
                    Directory.CreateDirectory(dir);

                // Build File Path string
                string strStamp = (DateStamp) ? "_" + DateTime.Now.ToString("yyyyMMdd_HHmmss") : "";
                strXMLFile = DirPath.Value + "\\" + FileName.Value + strStamp + ".xml";

                // Initialize a new instance of the StreamWriter class
                using (var newFile = new StreamWriter(DirPath.Value))
                {
                    // Write the file.
                    newFile.WriteLine(XMLContent);
                }
                // Return the file path on success.
                return strXMLFile;
            }
            else
                // Return warning when any of input value is NULL.
                return "Input parameters with NULL detected";
        }
        catch (Exception ex)
        {
            // Return null on error.
            return ex.Message.ToString();
        }
    }
    [SqlFunction]
    public static SqlString ReadXMLFile(SqlString FilePath)
    {
        // Parameters:
        // FilePath: The file path to the XML file.
        try
        {
            // Declare local variable
            string fileContent = "";
            // Check paremeter for null.
            if (!FilePath.IsNull)
            {
                // Initialize a new instance of the StreamReader class for the specified path.
                var fileStream = new FileStream(FilePath.Value, FileMode.Open, FileAccess.Read);
                using (var streamReader = new StreamReader(fileStream))
                {
                    fileContent = streamReader.ReadToEnd();
                }
            }
            // Return XML document
            return fileContent;
        }
        catch (Exception ex)
        {
            // Send exception message on error.
            return ex.Message.ToString();
        }
    }
};