<#
##########################################################################################################
##########################################################################################################


#1.Import solution from database/dacpac

#2.re-organize the folder/files
#2.1 create folders
#2.2 rename file name as schema.objectname.sql
#2.3 check the object_type and move files accordingly

#3. delete empty folder
#4. clean up & re-mapping project file

##########################################################################################################
##########################################################################################################
#>

function DB_folder_mapping
{
   param(
        [String] $old_repo_path, 
        [String] $new_repo_path, 
        [String] $prjfile
   )

        ##defines parameters for project & source files 

        #$old_repo_path = "C:\ReleaseRoot\Database\Source\Statement"
        #$new_repo_path = "C:\src\sql\myPCard_Global_Statement"
        #$prjfile = "C:\src\sql\myPCard_Global_Statement\myPCard_Global_Statement.sqlproj"


        $old_repo = Get-ChildItem $old_repo_path -Recurse -File
        $old_repo_dir = Get-ChildItem $old_repo_path -Recurse -Directory 
        $new_repo = Get-ChildItem $new_repo_path -Recurse -File -Include *.sql | Sort-Object
        $new_repo_dir = Get-ChildItem $new_repo_path -Recurse -Directory  | Sort-Object

        $now = Get-Date -Format "yyyyMMdd_HHmmss"
        $output = $new_repo_path+"\missing_objects_"+$now+".csv"


        #2.re-organize the folder/files
        #2.1 create folders

        $folders = "Functions","Partitioning","Procedures","Service Broker","Synonyms","Tables","Triggers","Types","Views"

        foreach($folder in $folders)
        {
            $path = $new_repo_path+"\"+$folder    

            $exists = Test-Path -Path  $path

            if($exists -ne $True) {

                md -Force $path
            }
        }

        #create sub folder
        foreach($dir in $old_repo_dir) 
        {
    
            $folder = $dir.FullName.Replace($old_repo_path,$new_repo_path) 
    
            $exists = Test-Path -Path $folder 

            if($exists -ne $True) {

                md -Force $folder
            }
        }


        echo "#2.2 rename file name as schema.objectname.sql"
        foreach ($file in $new_repo) 
        {
            #$schema
            #$object

            #check before renaming
            if($file.Name.Split(".").Count -lt 3){

                $cnt = $file.FullName.Replace($new_repo_path,"").Split("\").Count
                $schma = $file.FullName.Replace($new_repo_path,"").Split("\")[1]
                $obj_type = $file.FullName.Replace($new_repo_path,"").Split("\")[2]
                $sql_file = $file.FullName.Replace($new_repo_path,"").Split("\")[$cnt-1]

                $sql_file_new = $schma+"."+$sql_file

                if ($schma -notin ("Assemblies","bin","obj","Security","Service Broker","Storage"))
                {
        
                    Rename-Item -Path $file.FullName -NewName $sql_file_new
        
        
                    #echo "#2.re-organize the folder/files"
                    foreach($file_old in $old_repo)
                    {
            
                        #$sql_file_new

                        if($file_old.name.toLower().Replace("prc","sql") -eq $sql_file_new) 
                        {
                    
                            #$file.FullName.Replace($file.Name,$sql_file_new)
                            Move-Item -Path $file.FullName.Replace($file.Name,$sql_file_new) -Destination $file_old.DirectoryName.Replace($old_repo_path,$new_repo_path)
                        }
                    }
            
                    #echo "#2.3 check the object_type and move files accordingly if files not found from SVN"            

                    $exists = Test-Path -Path $file.FullName.Replace($file.Name,$sql_file_new)
            
                    if($exists -eq $True)
                    {
                        switch ($obj_type) 
                        {
                            "Functions"           {Move-Item -Path $file.FullName.Replace($file.Name,$sql_file_new) -Destination $new_repo_path"\Functions"}
                            "Partitioning"        {Move-Item -Path $file.FullName.Replace($file.Name,$sql_file_new) -Destination $new_repo_path"\Partitioning"}
                            "Stored Procedures"   {Move-Item -Path $file.FullName.Replace($file.Name,$sql_file_new) -Destination $new_repo_path"\Procedures"}
                            "Synonyms"            {Move-Item -Path $file.FullName.Replace($file.Name,$sql_file_new) -Destination $new_repo_path"\Synonyms"}                    
                            "Tables"              {Move-Item -Path $file.FullName.Replace($file.Name,$sql_file_new) -Destination $new_repo_path"\Tables"}
                            "Triggers"            {Move-Item -Path $file.FullName.Replace($file.Name,$sql_file_new) -Destination $new_repo_path"\Partitioning"}
                            "User Defined Types"  {Move-Item -Path $file.FullName.Replace($file.Name,$sql_file_new) -Destination $new_repo_path"\Types"}
                            "Views"               {Move-Item -Path $file.FullName.Replace($file.Name,$sql_file_new) -Destination $new_repo_path"\Views"}
                        }

                        $obj_type+","+$sql_file_new >> $output
                    }
                } 
            }
        }



        echo "#3. delete empty folders and subfolders if any exist"
        do {
    
            $dirs = gci $new_repo_path -Directory -Recurse | where {(gci $_.FullName).count -eq 0} | select -ExpandProperty fullname

            foreach($dir in $dirs)
            {            
                Remove-Item $dir
            }

            #$dirs | Foreach-Object { Remove-Item $_ }
        } while ($dirs.count -gt 0)



        #4. clean up & re-mapping project file
        #4.1 delete old folders

        [XML]$xmldoc = Get-Content $prjfile


        echo "#4.1.1 delete old folders"

        <#
        <ItemGroup>
            <Folder Include="Properties" />
            ...
            ...
            <Folder Include="myPCard_Global_Routetenance\Synonyms\" />
          </ItemGroup>
        #>


        foreach($node in $xmldoc.Project.ItemGroup[0].SelectNodes("*"))
        {
            if($xmldoc.Project.ItemGroup[0].FirstChild -ne $node)
            {
                $xmldoc.Project.ItemGroup[0].RemoveChild($node)
            }
        }

        echo "#4.1.2 delete old folders"
        <#
          <ItemGroup>
            <Build Include="dbo\Tables\SOURCE_SCRIPT_VERSION.sql" />
            <Build Include="dbo\Tables\COMPANY_STORAGE_IMAGE_PERSONAL_OCR_DATABASE.sql" />
            ...
            ...
            <Build Include="dbo\Tables\PROC_PERFORMANCE_TRACE.sql" />
          </ItemGroup>
        #>

        foreach($node in $xmldoc.Project.ItemGroup[1].SelectNodes("*"))
        {
            if($xmldoc.Project.ItemGroup[1].FirstChild -ne $node)
            {
                $xmldoc.Project.ItemGroup[1].RemoveChild($node)
            }
        }

        #get new folders & files
        $new_repo = Get-ChildItem $new_repo_path -Recurse -File -Include *.sql | Sort-Object
        $new_repo_dir = Get-ChildItem $new_repo_path -Recurse -Directory  | Sort-Object

        #4.2 add new folders
        echo "#4.2.1 add new folders"
        foreach($dir in $new_repo_dir)
        { 
            if($dir.FullName.Replace($new_repo_path+"\","").split("\")[0] -notin ("bin","obj","Import Schema Logs"))
            {
                $copy = $xmldoc.Project.ItemGroup[0].FirstChild.Clone()
                $copy.Include = $dir.FullName.Replace($new_repo_path+"\","")+"\"
    
                $xmldoc.Project.ItemGroup[0].AppendChild($copy)
            }
        }



        echo "#4.2.2 add new folders"
        foreach($file in $new_repo)
        {
    
             if($file.FullName.Replace($new_repo_path+"\","").split("\")[0] -notin ("bin","obj","Import Schema Logs"))
             {
                $copy = $xmldoc.Project.ItemGroup[1].FirstChild.Clone()
                $copy.Include = $file.FullName.Replace($new_repo_path+"\","")
    
                $xmldoc.Project.ItemGroup[1].AppendChild($copy)

             }   
        }

        
        # don't remove property folder
        #$xmldoc.Project.ItemGroup[0].RemoveChild($xmldoc.Project.ItemGroup[0].FirstChild)

        echo "deleted the first child"
        $xmldoc.Project.ItemGroup[1].RemoveChild($xmldoc.Project.ItemGroup[1].FirstChild)

        echo "save xml doc"
        $xmldoc.Save($prjfile)
}




#DB_folder_mapping "C:\Release_R2\Database\Source\Route" "C:\src\sqlproject\Production_R2\myPCard_Global_Route" "C:\src\sqlproject\Production_R2\myPCard_Global_Route\myPCard_Global_Route.sqlproj"
#DB_folder_mapping "C:\Release_R2\Database\Source\Interface" "C:\src\sqlproject\Production_R2\myPCard_Global_Interface" "C:\src\sqlproject\Production_R2\myPCard_Global_Interface\myPCard_Global_Interface.sqlproj"
#DB_folder_mapping "C:\Release_R2\Database\Source\Storage" "C:\src\sqlproject\Production_R2\Production_R2\myPCard_Global_Storage" "C:\src\sqlproject\Production_R2\myPCard_Global_Storage\myPCard_Global_Storage.sqlproj"
#DB_folder_mapping "C:\Release_R2\Database\Source\Statement" "C:\src\sqlproject\Production_R2\Statement" "C:\src\sqlproject\Production_R2\Statement\Statement.sqlproj"
#DB_folder_mapping "C:\Release_R2\Database\Source\Message" "C:\src\sqlproject\Production_R2\myPCard_Global_Message" "C:\src\sqlproject\Production_R2\myPCard_Global_Message\myPCard_Global_Message.sqlproj"

DB_folder_mapping "C:\Release_R2\Database\Source\Main" "C:\src\sqlproject\Production_R2\Main" "C:\src\sqlproject\Production_R2\Main\Main.sqlproj"


<#
cls


#build database solution
cd 'C:\Program Files (x86)\MSBuild\14.0\Bin'
.\msbuild.exe C:\src\sqlproject\Production_R2\Production_R2\myPCard_Global_Route\Fraedom.sln /t:Build

#.\msbuild.exe "C:\src\sqlproject\Production_R2\myPCard_Global_Route\myPCard_Global_Route.sqlproj" /t:Build

#.\msbuild.exe "C:\src\sqlproject\Production_R2\myPCard_Global_Interface\myPCard_Global_Interface.sqlproj" /t:Build

#.\msbuild.exe "C:\src\sqlproject\Production_R2\myPCard_Global_Message\myPCard_Global_Message.sqlproj" /t:Build

#.\msbuild.exe "C:\src\sqlproject\Production_R2\myPCard_Global_Statement\myPCard_Global_Statement.sqlproj" /t:Build

#.\msbuild.exe "C:\src\sqlproject\Production_R2\myPCard_Global_Storage\myPCard_Global_Storage.sqlproj" /t:Build

#.\msbuild.exe "C:\src\sqlproject\Production_R2\Main\Main.sqlproj" /t:Build






cd 'C:\Program Files (x86)\Microsoft SQL Server\140\DAC\bin'

#generate deploy report
.\sqlpackage.exe /a:DeployReport /sf:"C:\src\sqlproject\Production_R2\Main\bin\Debug\Main.dacpac" /tcs:"Data Source=.;Integrated Security=True;Persist Security Info=False;Pooling=False;MultipleActiveResultSets=False;Connect Timeout=60;Encrypt=False;TrustServerCertificate=True;database=myPCard00" /v:myPCard_Global_Interface="myPCard_Global_Interface" /v:myPCard_Global_Route="myPCard_Global_Route" /op:"C:\src\sqlproject\Production_R2\output\DeployReport.xml" /DiagnosticsFile:"C:\src\sqlproject\Production_R2\output\log_deploy.txt" 


#generate diff between project & live database
.\sqlpackage.exe /a:Script /sf:"C:\src\sqlproject\Production_R2\Main\bin\Debug\Main.dacpac" /tcs:"Data Source=.;Integrated Security=True;Persist Security Info=False;Pooling=False;MultipleActiveResultSets=False;Connect Timeout=60;Encrypt=False;TrustServerCertificate=True;database=myPCard00" /v:myPCard_Global_Interface="myPCard_Global_Interface" /v:myPCard_Global_Route="myPCard_Global_Route" /op:"C:\src\sqlproject\Production_R2\output\Main.sql" /DiagnosticsFile:"C:\src\sqlproject\Production_R2\output\log_script.txt" 


#SqlPackage.exe /Action:DriftReport /OutputPath:C:\src\sqlproject\Production_R2\output\DriftReport.xml /TargetConnectionString:"Data Source=localhost;Initial Catalog=myPCard00;Integrated Security=True;Pooling=False;MultipleActiveResultSets=False;Connect Timeout=60;Encrypt=False;TrustServerCertificate=True;"
#>
