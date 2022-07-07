# GitIngest.rb

Dependencies:
 * Ruby (tested using ruby 2.6.6p146 [x64-mingw32])
 * Git (tested using git version 2.37.0.windows.1)
 * 7z (tested using 7-Zip 22.0)
 * tar

This script is used to commit a batch of project 7z or tgz archives to a Git repository. The script first sorts the archive files by date (based on the archive filename, not the archive last-update or created-at timestamps) and then sequentially commits each revision.

The script takes two inputs: zipfiles.txt (a text file where each line contains a path to a zipped source folder) and output (the folder containing the .git repository where the zipped source files are unzipped and committed).

Each line of zipfiles.txt should contain a path to a 7z project archive, e.g.:

```
C:\SomeDir\SoftwareProject_331x12_20190704.7z
C:\SomeDir\SoftwareProject_331x12_20190705.7z
```

The filenames may also be in the following format (no change is necessary):

```
C:\SomeDir\SoftwareProject_331x12_VS2008_20190704.7z
C:\SomeDir\SoftwareProject_331x12_VS2008_20190705.7z
```

Users may need to check in project histories containing multiple branches. This script does not directly address this scenario, but a workaround is possible where the user can specify a list of project archives on a single branch in zipfiles.txt. After checking in this branch, the user must manually re-populate zipfiles.txt with the archives from another branch.

The archive naming convention is assumed to be:  
```[Project name]_[Major version]x[Minor version]_[YYYYMMDD].7z```

Execute the script by calling it with the two command-line inputs:  
```ruby .\gitingest.rb --zipfiles .\zipfiles.txt --output "C:/SomeDir/OutDir"```

Using this script (and the default Git log view), the project history commits will appear to have happened at the same time. Try using the following option to display commits by author-date:  
```git log --author-date-order```

Alternatively, [GitExtensions](http://gitextensions.github.io/) provides an option to enable sorting by author-date: View->Sort commits by author date.

This script assumes that your main project folder already has a .gitignore in place. When cleaning out the folder between commits, this script leaves the .gitignore file in-place to avoid committing undesired artifacts contained in the archives. Additionally, make sure you don't delete the hidden .git and .vs folders; because these folders being with a period, they are 'transparent' to the commit process.

It is recommended to manually compare the repository commit-history against the archives being checked in; this script assumes that any archives in zipfiles have *not* already 
been checked in. Thus, running the script twice with the same set of archives will result in each archive being committed twice. This script is *not* idempotent.

This script leaves the working directory in a dirty state (by deleting all non-hidden files). Expect to have to 'reset all changes' using Git after executing this script. 

It is possible to write the files contained in a folder to a textfile using this syntax:

```ls > zipfiles.txt```

The output needs to be manually edited to remove anything other than file paths on each line. Ensure that the resulting zipfiles.txt file is in UTF-8 format. The batch-file write operator (>) creates files in a different encoding. Use Notepad++ to change the encoding.

