pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.Config
import Caelestia.Models
import qs.services
import qs.utils

Searcher {
    id: root

    readonly property string currentNamePath: `${Paths.state}/wallpaper/path.txt`
    readonly property string modePath: `${Paths.state}/wallpaper/mode.txt`
    readonly property list<string> smartArg: ["--no-smart"]
    readonly property string fallback: Quickshell.shellPath("assets/wallpaper.webp")

    property bool isLive: false
    property bool showPreview: false
    readonly property string current: showPreview ? previewPath : actualCurrent
    property string previewPath
    property string actualCurrent
    property bool previewColourLock
    property bool pendingPreviewClear

    function getCategoryFor(w: FileSystemEntry): string {
        let category = w.parentDir.slice(Paths.wallsdir.length + 1);
        if (category.includes("/"))
            category = category.slice(0, category.indexOf("/"));
        return category;
    }

    function setRandom(): void {
        GlobalConfig.background.wallpaperEnabled = true;
        Quickshell.execDetached(["/home/sidlakhani/.local/bin/wallpaper", "random"]);
    }

    function setWallpaper(path: string): void {
        actualCurrent = path;
        GlobalConfig.background.wallpaperEnabled = true;
        Quickshell.execDetached(["/home/sidlakhani/.local/bin/wallpaper", "static", path]);
    }

    function commitLive(thumb: string, videoPath: string, isGif: bool): void {
        actualCurrent = thumb;
        previewPath = thumb;
        isLive = false;
        if (Colours.scheme === "dynamic")
            previewColourLock = true;
        Quickshell.execDetached(["/usr/bin/pkill", "-x", "mpvpaper"]);
        Quickshell.execDetached([
            "/usr/bin/bash",
            "-c",
            "cd /home/sidlakhani && exec /home/sidlakhani/.local/bin/wallpaper \"$1\" \"$2\"",
            "wallpaper",
            isGif ? "gif" : "video",
            videoPath
        ]);
    }

    function preview(path: string): void {
        previewPath = path;
        showPreview = true;

        if (Colours.scheme === "dynamic") {
            if (getPreviewColoursProc.running)
                getPreviewColoursProc.running = false;
            getPreviewColoursProc.running = true;
        }
    }

    function stopPreview(): void {
        showPreview = false;
        if (previewColourLock)
            pendingPreviewClear = true;
        else
            Colours.showPreview = false;
    }

    onPreviewColourLockChanged: {
        if (!previewColourLock && pendingPreviewClear)
            Colours.showPreview = false;
    }

    list: wallpapers.entries
    key: "relativePath"
    useFuzzy: GlobalConfig.launcher.useFuzzy.wallpapers
    extraOpts: useFuzzy ? ({}) : ({
            forward: false
        })

    IpcHandler {
        function get(): string {
            return root.actualCurrent;
        }

        function set(path: string): void {
            root.setWallpaper(path);
        }

        function list(): string {
            return root.list.map(w => w.path).join("\n");
        }

        function setEnabled(enabled: string): void {
            GlobalConfig.background.wallpaperEnabled = (enabled === "true" || enabled === "1");
        }

        function enable(): void {
            GlobalConfig.background.wallpaperEnabled = true;
        }

        function disable(): void {
            GlobalConfig.background.wallpaperEnabled = false;
        }

        function setLive(live: string): void {
            root.isLive = (live === "true" || live === "1");
        }

        function getLive(): bool {
            return root.isLive;
        }

        target: "wallpaper"
    }

    FileView {
        path: root.modePath
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            root.isLive = text().trim() === "live";
        }
        onLoadFailed: {
            root.isLive = false;
        }
    }

    FileView {
        path: root.currentNamePath
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            let wall = text().trim();
            if (!wall) {
                wall = root.fallback;
                Quickshell.execDetached(["caelestia", "wallpaper", "-f", root.fallback, ...root.smartArg]);
            }
            root.actualCurrent = wall;
            root.previewColourLock = false;
        }
        onLoadFailed: {
            root.actualCurrent = root.fallback;
            root.previewColourLock = false;
            Quickshell.execDetached(["caelestia", "wallpaper", "-f", root.fallback, ...root.smartArg]);
        }
    }

    FileSystemModel {
        id: wallpapers

        recursive: true
        watchChanges: true
        path: Paths.wallsdir
        filter: FileSystemModel.Images
    }

    Process {
        id: getPreviewColoursProc

        command: ["caelestia", "wallpaper", "-p", root.previewPath, ...root.smartArg]
        stdout: StdioCollector {
            onStreamFinished: {
                Colours.load(text, true);
                Colours.showPreview = true;
            }
        }
    }
}
