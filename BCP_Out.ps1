Function BCP_Out {

    # Parameter help description    
    param(
        [String] $Sqlserver, #SQL Server Source
        [String] $Path       #BCP output folder
    )
    #Log file
    $Log = $Path+"\Status.txt"
    #data folder
    $Folder = $Path+"\data"    

    $exists = Test-Path -Path $Folder
    if ($exists -ne $True) {
        mkdir -Force $Folder
    }

    #bcp our local databases
    bcp.exe "select DATABASE_ID from myPCard_Global_Route.dbo.GLOBAL_DATABASES where DATABASE_ID not in ('myPCard01','myPCard0S','myPCard00')" queryout "$Path\Databases.txt" -T -c -S $Sqlserver

    #Foreach query list and bcp out data to the folder defined in above
    Get-Content "$Path\Tables.txt" | ForEach-Object {
        $Query = $_;        
        $Table = $Query.ToString().Split(" as ")[1].Replace("[","").Replace("]","")
        $Output = "$Folder\$Table.txt";

        $date = Get-Date
        "$date" + " : Starting BCP: "+ "$Table" | Out-File $Log -Append       
        
        bcp.exe $Query.ToString() queryout $Output -T -n -S $Sqlserver

        $date2 = Get-Date;
        "$date2" + " : Ending BCP: "+ "$Table " + ($date2 - $date).TotalSeconds  | Out-File $Log -Append
    }
}

#BCP_Out "localhost" "C:\src\sqlproject\Bcp"


<#
Tables.txt

select master_element_id, child_element_id, language_id_txt, pk_ref, value, value_2, value_3 from myPCard_Global_Route.dbo.REF_LD_VALUE as [dbo.local_ref_ld_value]
select eti_type, language_id_txt, eti_value, eti_translated_value from myPCard_Global_Route.dbo.ETI_LD_VALUE as [dbo.local_eti_ld_value]
select language_id_txt, text_key, lang_text from myPCard_Global_Route.dbo.language_general_text as [dbo.local_language_general_text]
select language_id_txt, hierarchy_language_id, hierarchy_level from myPCard_Global_Route.dbo.TXT_LANGUAGE_HIERARCHY as [dbo.local_txt_language_hierarchy]
select language_id_txt, description, language_code, translation_export_flag, translation_language_description from myPCard_Global_Route.dbo.txt_language as [dbo.local_txt_language]

#>


<#
Databases.txt

myPCard01
Groundhog

#>