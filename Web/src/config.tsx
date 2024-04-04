export const applicationName = "Feature Logging";
export const applicationDescription = "Feature Logging is a small productivity tool to log Vero features.";
export const applicationDetails = (
    <>
        This tools lets you collection and log Vero features and then copy the relevant data to paste in the
        Vero scripts app.
    </>
);
export const macScreenshotWidth = 1416;
export const macScreenshotHeight = 874;
export const windowsScreenshotWidth = 1200;
export const windowsScreenshotHeight = 800;

export const deploymentWebLocation = "/app/featurelogging";

export const versionLocation = "featurelogging/version.json";

export const macDmgLocation = "featurelogging/macos/Feature%20Logging%20";
export const macReleaseNotesLocation = "releaseNotes-mac.json";

export const windowsInstallerLocation = "featurelogging/windows";
export const windowsReleaseNotesLocation = "releaseNotes-windows.json";

export type Platform = "macOS" | "windows";

export const platformString: Record<Platform, string> = {
    macOS: "macOS",
    windows: "Windows"
}

export interface Links {
    readonly location: (version: string, flavorSuffix: string) => string;
    readonly actions: {
        readonly name: string;
        readonly action: string;
        readonly target: string;
        readonly suffix: string;
    }[];
}

export const links: Record<Platform, Links | undefined> = {
    macOS: {
        location: (version, suffix) => `${macDmgLocation}${suffix}v${version}.dmg`,
        actions: [
            {
                name: "default",
                action: "download",
                target: "",
                suffix: "",
            }
        ]
    },
    windows: {
        location: (_version, suffix) => `${windowsInstallerLocation}${suffix}`,
        actions: [
            {
                name: "current",
                action: "install",
                target: "",
                suffix: "/setup.exe",
            },
            {
                name: "current",
                action: "read more about",
                target: "_blank",
                suffix: "",
            }
        ]
    },
};
