if ($ExecutionContext.SessionState.LanguageMode -eq "FullLanguage") {
    Invoke-Expression (&starship init powershell)
    Import-Module -Name Terminal-Icons
}

function title($new_title) {
    if ($null -eq $new_title) {
        $new_title = (Get-Location | Get-Item).Name
    }
    $Host.UI.RawUI.WindowTitle = $new_title
}

function cdr {
    cd "$(git rev-parse --show-toplevel)"
}

function sub($envid) {
    if ($envid -eq "prd") {
        $envid = "prod"
    }
    az account set --subscription dpc-servicePortal-$envid
    az account show
}

function stack($envid) {
    if ($envid -eq "prod") {
        $envid = "prd"
    }
    pulumi stack select sadpc/$envid
}

function swap($envid) {
    stack $envid
    sub $envid
} 

function goto {
    param (
        [ArgumentCompleter({
                param ($Command, $Parameter, $WordToComplete, $CommandAst, $FakeBoundParams)

                # Get-LocalUser | Where-Object { $_.Name -like "*$WordToComplete*" }
                $GIT_ROOT = $(git rev-parse --show-toplevel)
                $WORKSPACE_JSON = $(Get-Content $GIT_ROOT/workspace.json -Raw | ConvertFrom-Json)
                echo $WORKSPACE_JSON
                ($WORKSPACE_PROJECTS.psobject.properties | select name) | Where-Object { $_.Name -match "\w*$somewhere\w*" }
            })]
        [string] $someplace
    )

    echo "$someplace"
}

function go($somewhere) {
    $GIT_ROOT = $(git rev-parse --show-toplevel)

    # no parameter, go to git root
    if ($null -eq $somewhere) {
        echo "Going home"
        cd $GIT_ROOT
        return
    }

    $WORKSPACE_JSON = $(Get-Content $GIT_ROOT/workspace.json -Raw | ConvertFrom-Json)
    $WORKSPACE_PROJECTS = $WORKSPACE_JSON.projects
    $EXACT_PROJECT_MATCH = $WORKSPACE_PROJECTS.$somewhere

    # exact match, go to it
    if ($null -ne $EXACT_PROJECT_MATCH) {
        echo "Entering $somewhere through $GIT_ROOT/$EXACT_PROJECT_MATCH"
        cd "$GIT_ROOT/$EXACT_PROJECT_MATCH"
        return
    }

    # search workspace projects
    $MATCHED_PROJECTS = ($WORKSPACE_PROJECTS.psobject.properties | select name) -match "\w*$somewhere\w*"
    # ($WORKSPACE_PROJECTS.psobject.properties | select name) -match "\w*$somewhere\w*" | % { echo $_ }

    # no matched projects, list available projects
    if ($MATCHED_PROJECTS.Length -eq 0) {
        echo "No projects found that match: $somewhere"
        echo "Valid projects include:"
        $WORKSPACE_JSON | % { echo $_.Name }
        return
    }

    # matched a single project, go to it
    if ($MATCHED_PROJECTS.Length -eq 1) {
        $PROJECT = $MATCHED_PROJECTS[0].Name
        $PROJECT_PATH = $WORKSPACE_PROJECTS.$PROJECT
        echo "Teleporting to $PROJECT"
        cd "$GIT_ROOT/$PROJECT_PATH"
        return
    }

    # matched multiple projects, list them
    echo "Matched $($MATCHED_PROJECTS.Count) projects:"
    $MATCHED_PROJECTS | % { echo $_.Name }
    return
}

function branch($branch) {
    git checkout -b $branch
    git push --set-upstream origin $branch
}

function cap($message) {
    git status
    git add *
    git commit -m $message
    git pull
    git push
}

# function DeleteTag($tag) {
#     git push --delete origin $tag
#     git tag --delete $tag
# }

function prune {
    git checkout main; 
    git remote update origin --prune; 
    git branch -vv | Select-String -Pattern ": gone]" | 
        % { $_.toString().Trim().Split(" ")[0] } | 
        % { git branch -D $_ }
}

function main {
    git pull origin main
}

function sln {
    Get-ChildItem -Recurse -Filter *.sln | 
        % { $_.DirectoryName } | 
        % { Invoke-Expression "$_/*.sln" }
}

function q($match) {
    $dirs = Get-ChildItem -Attributes Directory -Filter *$match*
    if ($dirs.Length -eq 1) {
        Set-Location $dirs[0].Name
    } else {
        write-host "-- Multiple matches" -ForegroundColor DarkCyan
        $dirs | % { write-host " - $($_.Name)" -ForegroundColor DarkCyan }
        write-host "$dirs"
        write-host ""
    }
}

function hist($match) {
    get-history | where { $_.CommandLine.ToString() -match $match } | select -Last 10 
}

function hi($num) {
    Invoke-History $num
}
