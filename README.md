# GitIngest.rb

Dependencies:
 * Ruby (tested using ruby 2.3.3p222 [i386-mingw32]
 * Git (tested using git version 2.24.0.windows.2)
 * 7z (tested using 7-Zip 9.10 beta)

This script is used to commit a batch of project 7z archives to a Git repository. The script first sorts the archive files by date (based on the archive filename, not the archive last-update or created-at timestamps) and then sequentially commits each revision.

A file called 'zipfiles.txt' is expected to be located in the same location as the script. Each line of zipfiles.txt should contain a path to a 7z project archive, e.g.:

```
C:\Vital-Sim\Git_xfer_new_2\VSLS_331x12_20190704.7z
C:\Vital-Sim\Git_xfer_new_2\VSLS_331x12_20190705.7z
```

Users may need to check in project histories containing multiple branches. This script does not directly address this scenario, but a workaround is possible where the user can specifcy a list of project archives on a single branch in zipfiles.txt. After checking in this branch, the user must manually re-populate zipfiles.txt with the archives from another branch.

The archive naming convention is assumed to be:
```[Project name]_[Major version]x[Minor version]_[YYYYMMDD].7z```

The 

This script takes no command-line input. Just execute this script in the same directory as zipfiles.txt, e.g.:
```ruby gitingest.rb```

Using this script (and the default Git log view), the project history commits will appear to have happened at the same time. Try using the following option to display commits by author-date:
```git log --author-date-order```

Alternatively, GitExtensions provides an option to enable sorting by author-date: View->Sort commits by author date.

This script assumes that your main project folder already has a .gitignore in place. When cleaning out the folder between commits, this script leaves the .gitignore file in-place to avoid committing undesired artifacts contained in the archives.

It is recommended to manually compare the repository commit-history against the archives being checked in; this script assumes that any archives in zipfiles.txt have *not* already been checked in. Thus, running the script twice with the same set of archives will result in each archive being committed twice.

This script leaves the working directory in a dirty state (by deleting all non-hidden files). Expect to have to 'reset all changes' using Git after executing this script. 