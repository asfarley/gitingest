# GitIngest.rb

This script is used to commit a batch of project 7z or tgz archives to a Git repository. The script first sorts the archive files by date (based on the archive filename, not the archive last-update or created-at timestamps) and then sequentially commits each revision.

Dependencies:
 * Ruby (tested using ruby 2.6.6p146 [x64-mingw32])
 * Git (tested using git version 2.37.0.windows.1)
 * 7z (tested using 7-Zip 22.0)
 * tar
 
## How to use

The script takes two (or more) inputs: --output (the folder containing the .git repository where the zipped source files are unzipped and committed) and a list of input folders containined zipped source files.

It is recommended to manually compare the repository commit-history against the archives being checked in; this script assumes that any archives in zipfiles have *not* already 
been checked in. Thus, running the script twice with the same set of archives will result in each archive being committed twice. This script is *not* idempotent.

This script does not manage branches; check out the branch intended for commits before running this script.

The archive naming convention is assumed to be:  
```[Project name]_[Major version]x[Minor version]_[YYYYMMDD].7z```

Execute the script by calling it with the two command-line inputs:  
```ruby .\gitingest.rb --outpout [OUTPUT_PATH] [INPUT_PATHS...]```

In the above, `INPUT_PATHS` can expand to one or more folder paths to zipped source files. For example:

```ruby .\gitingest.rb --outpout ..\repo_folder\ ..\zipsource_folder\```

## Viewing the results

Using this script (and the default Git log view), the project history commits will appear to have happened simultaneously at the current time (rather than the historic time contained in the archive's filename). Try using the following option to display commits by author-date:  
```git log --author-date-order```

Alternatively, [GitExtensions](http://gitextensions.github.io/) provides an option to enable sorting by author-date: View->Sort commits by author date.

## .gitignore

This script assumes that your main project folder already has a .gitignore in place. When cleaning out the folder between commits, this script leaves the .gitignore file in-place to avoid committing undesired artifacts contained in the archives. Additionally, make sure you don't delete the hidden .git and .vs folders; because these folders being with a period, they are 'transparent' to the commit process.
