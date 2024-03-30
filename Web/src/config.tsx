export const applicationName = "Feature Logging";
export const applicationDescription = "Feature Logging is a small productivity app to log Vero features.";
export const applicationDetails = (
    <>
        This utility lets you collection and log Vero features and then copy the relevant data to paste in the
        Vero scripts app.
    </>
);
export const macScreenshotWidth = 1416;
export const macScreenshotHeight = 874;
export const windowsScreenshotWidth = 940;
export const windowsScreenshotHeight = 580;

export const deploymentWebLocation = "/app/featurelogging";

export const versionLocation = "featurelogging/version.json";

export const macDmgLocation = "featurelogging/macos/Feature%20Logging%20";
export const macReleaseNotesLocation = "releaseNotes-mac.json";

export const windowsInstallerLocation = "featuretracker/windows";
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
    windows: undefined,
};
