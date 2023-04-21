import std.stdio;

import std.getopt;
import std.file: exists, mkdir, isDir;
import std.array: split, replace;
import std.algorithm.mutation: remove;
import std.algorithm.searching: canFind, count;
import std.process: wait, spawnProcess, ProcessConfig = Config;
import std.datetime: Clock, SysTime;
import std.format: format;
import std.path: dirSeparator;

import core.stdc.stdlib: exit;

import sily.getopt;
import std.path : absolutePath, buildNormalizedPath, expandTilde;
// import sily.path: fixPath; // this version has kind of wrong expansion
string fixPath(string p) {
    return p.expandTilde.absolutePath.buildNormalizedPath;
}

int main(string[] args) {
    string addPath = "";
    string removePath = "";
    bool listPath = false;
    bool doBackup = false;
    string backupMessage = "";
    string branch = "";
    string origin = "";

    GetoptResult help = getopt(
        args,
        config.passThrough,
        config.bundling,
        config.caseSensitive,
        "add|a", "Add new backup path", &addPath,
        "remove|r", "Remove existing backup path", &removePath,
        "list|l", "Lists existing backup paths", &listPath,
        "backup|b", "Goes through each path and pushes it", &doBackup,
        "branch|B", "Sets upstream branch for --add, default is \"master\"", &branch,
        "origin|o", "Sets origin name for --add, default is \"origin\"", &origin,
        "message|m", "Commit message, default is \"Backup: %Y/%m/%d %H:%M:%S\"", &backupMessage
    );

    if (help.helpWanted) {
        printGetopt(
            "Usage:\nbackpack [args]",
            "Options",
            help.options
        );
    }
    
    checkPath();
    configRead();

    if (addPath.length) {
        string p = addPath.fixPath;
        if (p.exists && p.isDir) {
            string gitdir = p ~ dirSeparator ~ ".git";
            if (gitdir.exists && gitdir.isDir) {
                if (findPath(p) != -1) {
                    writeln("Error: path \"" ~ addPath ~ "\" is already added.");
                    return 1;
                }
                if (branch == "") branch = "master";
                if (origin == "") origin = "origin";

                backupPaths ~= BackupPath(p, origin, branch);
                configWrite();
            } else {
                writeln("Error: path \"" ~ addPath ~ "\" is not a git repository.");
                return 1;
            }
        } else {
            writeln("Error: path \"" ~ addPath ~ "\" is invalid.");
            return 1;
        }
    }

    if (removePath.length) {
        string p = removePath.fixPath;
        int pos = findPath(p);
        if (pos != -1) {
            backupPaths = backupPaths.remove(pos);
        } else {
            writeln("Error: path \"" ~ removePath ~ "\" is not in backup list.");
            return 1;
        }
    }

    if (listPath) {
        foreach (bkpath; backupPaths) {
            writeln(bkpath.path, ":", bkpath.origin, ":", bkpath.branch);
        }
    }

    if (doBackup) {
        string commitMessage = "";
        if (backupMessage.length) {
            commitMessage = backupMessage;
        } else {
            SysTime time = Clock.currTime();
            commitMessage = "Backup: ";
            // 2023/12/31 23:59:59
            commitMessage ~= "%d/%02d/%02d %02d:%02d:%02d"
                .format(time.year, time.month, time.day, time.hour, time.minute, time.second);
        }
        foreach (bkpath; backupPaths) {
            // git diff --quiet --exit-code
            int ret = wait(
                    spawnProcess(["git", "diff", "--quiet", "--exit-code"], null, ProcessConfig.none, bkpath.path));
            if (ret == 1) {
                writeln("# Backing up: \"" ~ bkpath.path ~ "\"");
                wait(
                    spawnProcess(["git", "add", "."], null, ProcessConfig.none, bkpath.path));
                wait(
                    spawnProcess(["git", "commit", "-m", commitMessage], null, ProcessConfig.none, bkpath.path));
                wait(
                    spawnProcess(["git", "push", bkpath.origin, bkpath.branch], null, ProcessConfig.none, bkpath.path));
            } else {
                writeln("# Skipping: \"" ~ bkpath.path ~ "\", noting to commit");
            }
        }
    }

    return 0;
}

// maybe update it to format "/global/path/to/dir:origin:branch"
string configPath = "~/.config/backpack/backup_list";
string configPathOnly = "~/.config/backpack";
BackupPath[] backupPaths = [];

void checkPath() {
    if (!configPathOnly.fixPath.exists()) {
        mkdir(configPathOnly.fixPath);
    }
    if (!configPath.fixPath.exists()) {
        File f = File(configPath.fixPath, "w+");
        f.close();
    }
}

void configWrite() {
    string _out;
    for (int i = 0; i < backupPaths.length; ++i) {
        BackupPath p = backupPaths[i];
        _out ~= p.path ~ ":" ~ p.origin ~ ":" ~ p.branch;
        if (i + 1 != backupPaths.length) _out ~= "\n";
    }
    File f = File(configPath.fixPath, "w+");
    f.write(_out);
    f.close();
}

void configRead() {
    File f = File(configPath.fixPath, "r+");
    int i = 1;
    while (!f.eof) {
        string line = f.readln();
        if (line == "") break;
        line = line.replace('\n', "");
        if (line.count(':') != 2) {
            writeln("Error, unable to read config line \"", i, 
                "\", expected format is: \"absolutePath:originName:branchName\". Skipping.");
            ++i;
            continue;
        }
        string[3] l = line.split(':');
        backupPaths ~= BackupPath(l[0], l[1], l[2]);
        ++i;
    }
    f.close();
}

int findPath(string p) {
    for (int i = 0; i < backupPaths.length; ++i) {
        string path = backupPaths[i].path;
        if (path == p) {
            return i;
        }
    }
    return -1;
}

struct BackupPath {
    string path;
    string origin;
    string branch;
}

