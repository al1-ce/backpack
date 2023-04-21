import std.stdio;

import std.getopt;
import std.file: exists, mkdir, isDir;
import std.array: split, replace;
import std.algorithm.mutation: remove;
import std.algorithm.searching: canFind;
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

    GetoptResult help = getopt(
        args,
        config.passThrough,
        config.bundling,
        config.caseSensitive,
        "add|a", "Add new backup path", &addPath,
        "remove|r", "Remove existing backup path", &removePath,
        "list|l", "Lists existing backup paths", &listPath,
        "backup|b", "Goes through each path and pushes it", &doBackup,
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
                if (backupPaths.canFind(p)) {
                    writeln("Error: path \"" ~ addPath ~ "\" is already added.");
                    return 1;
                }
                backupPaths ~= p;
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
            writeln(bkpath);
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
        writeln(commitMessage);
        foreach (bkpath; backupPaths) {
            wait(spawnProcess(["git", "add", "."], null, ProcessConfig.none, bkpath));
            wait(spawnProcess(["git", "commit", "-m", commitMessage], null, ProcessConfig.none, bkpath));
            wait(spawnProcess(["git", "push"], null, ProcessConfig.none, bkpath));
        }
    }

    return 0;
}

string configPath = "~/.config/backpack/backup_list";
string configPathOnly = "~/.config/backpack";
string[] backupPaths = [];

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
        _out ~= backupPaths[i];
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
        backupPaths ~= line.replace('\n', '\0');
        ++i;
    }
    f.close();
}

int findPath(string p) {
    for (int i = 0; i < backupPaths.length; ++i) {
        string path = backupPaths[i];
        if (path == p) {
            return i;
        }
    }
    return -1;
}


