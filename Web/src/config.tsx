export const applicationName = "Feature Logging";
export const applicationDescription = "Feature Logging is a small productivity tool to log VERO features.";
export const applicationDetails = (
    <>
        This tools lets you collection and log VERO features and then copy the relevant data to paste in the
        VERO scripts app.
    </>
);
export const showMacScreenshot = true
export const macScreenshotWidth = 1416;
export const macScreenshotHeight = 874;
export const showWindowsScreenshot = true
export const windowsScreenshotWidth = 1200;
export const windowsScreenshotHeight = 800;

export const deploymentWebLocation = "/app/featurelogging";

export const versionLocation = "featurelogging/version.json";

export const enum PlatformLocation {
    DoNotShow,
    AppPortal,
    AppStore,
}

export const showMacInfo: PlatformLocation = PlatformLocation.AppStore;
export const macAppStoreLocation = "https://apps.apple.com/ca/app/feature-logging/id6480532610";
export const macReleaseNotesLocation = "releaseNotes-mac.json";

export const showIosInfo: PlatformLocation = PlatformLocation.AppStore;
export const iosAppStoreLocation = "https://apps.apple.com/ca/app/feature-logging-pad/id6740720721";
export const iosReleaseNotesLocation = "releaseNotes-ios.json";

export const showWindowsInfo: PlatformLocation = PlatformLocation.AppPortal;
export const windowsInstallerLocation = "featurelogging/windows";
export const windowsReleaseNotesLocation = "releaseNotes-windows.json";

export const showAndroidInfo: PlatformLocation = PlatformLocation.AppStore;
export const androidInstallerLocation = "https://play.google.com/store/apps/details?id=com.andydragon.feature_logging";
export const androidReleaseNotesLocation = "releaseNotes-android.json";

export const supportEmail = "andydragon@live.com";

export const hasTutorial = true;

export type Platform = "macOS" | "windows" | "iOS" | "android";

export const platformString: Record<Platform, string> = {
    macOS: "macOS",
    windows: "Windows",
    iOS: "iPad",
    android: "Android tablet",
}

export interface Links {
    readonly useAppStore?: true;
    readonly location: (version: string, flavorSuffix: string) => string;
    readonly actions: {
        readonly action: string;
        readonly target: string;
        readonly suffix: string;
    }[];
}

export const links: Record<Platform, Links | undefined> = {
    macOS: {
        useAppStore: true,
        location: (_version, _suffix) => macAppStoreLocation,
        actions: [
            {
                action: "install from app store",
                target: "_blank",
                suffix: "",
            }
        ]
    },
    iOS: {
        useAppStore: true,
        location: (_version, _suffix) => iosAppStoreLocation,
        actions: [
            {
                action: "install from app store",
                target: "_blank",
                suffix: "",
            }
        ]
    },
    windows: {
        location: (_version, suffix) => `${windowsInstallerLocation}${suffix}`,
        actions: [
            {
                action: "install the current version",
                target: "",
                suffix: "/setup.exe",
            },
            {
                action: "read more about the app",
                target: "_blank",
                suffix: "",
            }
        ]
    },
    android: {
        useAppStore: true,
        location: (_version, _suffix) => androidInstallerLocation,
        actions: [
            {
                action: "install from app store",
                target: "_blank",
                suffix: "",
            }
        ]
    },
};

export interface NextStep {
    readonly label: string;
    readonly page: string;
}

export interface Screenshot {
    readonly name: string;
    readonly width?: string;
}

export interface Bullet {
    readonly text: string;
    readonly image?: Screenshot;
    readonly screenshot?: Screenshot;
    readonly link?: string;
}

export interface PageStep {
    readonly screenshot: Screenshot;
    readonly title: string;
    readonly bullets: Bullet[];
    readonly previousStep?: string;
    readonly nextSteps: NextStep[];
}

export const tutorialPages: Record<string, PageStep> = {
    step1: {
        screenshot: { name: "Step 1", width: "806px" },
        title: "Start the Feature Logging application",
        bullets: [
            { text: "When the application starts, it will remember the last page used." },
            { text: "If the page is not correct, click the page drop down." }
        ],
        nextSteps: [
            {
                label: "Pick page",
                page: "step2",
            },
            {
                label: "Page is correct, skip",
                page: "step3",
            },
        ]
    },
    step2: {
        screenshot: { name: "Step 2", width: "989px" },
        title: "Find and Click the Page",
        bullets: [
            { text: "Find the page from the list of available pages." },
            { text: "Pages are listed alphabetically by hub, the page." }
        ],
        previousStep: "step1",
        nextSteps: [
            {
                label: "Next",
                page: "step3",
            }
        ]
    },
    step3: {
        screenshot: { name: "Step 3", width: "806px" },
        title: "Application is Ready to Start Logging Feature Candidates",
        bullets: [
            { text: "To quickly get the tags for the page, click the 'Copy tag' dropdown to pick the tag to copy.", image: { name: "Step 3a", width: "236px" } },
            { text: "Time to go to VERO and find photos." },
        ],
        previousStep: "step1",
        nextSteps: [
            {
                label: "Next",
                page: "step4",
            }
        ]
    },
    step4: {
        screenshot: { name: "Step 4", width: "806px" },
        title: "Search for Tags in VERO",
        bullets: [
            { text: "Go to Search in VERO, paste the tag (add the '#' is needed) and switch search to 'Hashtags'." },
            { text: "Find a photo you want to tag, then click the photo to see the photo details." }
        ],
        previousStep: "step3",
        nextSteps: [
            {
                label: "Next",
                page: "step5",
            }
        ]
    },
    step5: {
        screenshot: { name: "Step 5", width: "806px" },
        title: "Photo details",
        bullets: [
            { text: "With the details for the photo open, check the comments and take note if the photo was already picked by your page or another page for the hub." },
            { text: "Click the three dots to open the menu for the post and choose 'Copy a link to this Post'.", screenshot: { name: "Step 5a", width: "806px" } }
        ],
        previousStep: "step4",
        nextSteps: [
            {
                label: "Next",
                page: "step6",
            }
        ]
    },
    step6: {
        screenshot: { name: "Step 6", width: "806px" },
        title: "Return to the Feature Logging app",
        bullets: [
            { text: "Click the 'Add feature' button to add a feature." },
            { text: "The post link and the user alias (username) will be populated from the link copied in VERO.", screenshot: { name: "Step 6a", width: "806px" } },
        ],
        previousStep: "step5",
        nextSteps: [
            {
                label: "Next",
                page: "step7",
            }
        ]
    },
    step7: {
        screenshot: { name: "Step 7", width: "806px" },
        title: "Return to VERO",
        bullets: [
            { text: "Open the user's bio by clicking on the user's name." },
            { text: "Select and copy the user's full name." },
            { text: "Take note of the user's membership level for the page's hub." },
        ],
        previousStep: "step6",
        nextSteps: [
            {
                label: "Next",
                page: "step8",
            }
        ]
    },
    step8: {
        screenshot: { name: "Step 8", width: "806px" },
        title: "Return to Feature Logging app",
        bullets: [
            { text: "Fill in the rest of the data up to and including the description." },
            { text: "If the photo was already featured on this page, check that box. The feature in the list will get a red tag.", screenshot: { name: "Step 8a", width: "806px" } },
            { text: "If the photo was featured on a different page, check that box and fill in the date and page it was featured on.", screenshot: { name: "Step 8b", width: "806px" } },
        ],
        previousStep: "step7",
        nextSteps: [
            {
                label: "Next",
                page: "step9",
            },
        ]
    },
    step9: {
        screenshot: { name: "Step 9", width: "806px" },
        title: "Return to VERO",
        bullets: [
            { text: "Click back to close the user's bio, you should be at the photo post details." },
            { text: "Click the photo thumbnail to open it fullscreen." },
            { text: "Use you favorite method to screenshot the photo." },
            { text: "Name the screenshot to associate it with the feature (I use the user's full name)." },
        ],
        previousStep: "step8",
        nextSteps: [
            {
                label: "Continue finding photos",
                page: "step4",
            },
            {
                label: "Done finding photos",
                page: "step10",
            },
        ]

    },
    step10: {
        screenshot: { name: "Step 10", width: "806px" },
        title: "Time to Check User's Page Features",
        bullets: [
            { text: "To check the user's features, click the 'Copy tag' button for the page features." },
        ],
        previousStep: "step9",
        nextSteps: [
            {
                label: "Next",
                page: "step11",
            },
        ]
    },
    step11: {
        screenshot: { name: "Step 11", width: "806px" },
        title: "Return to VERO",
        bullets: [
            { text: "Go to the Search and paste the page tag in the search box and switch to 'Hashtags'." },
        ],
        previousStep: "step10",
        nextSteps: [
            {
                label: "User has features",
                page: "step12",
            },
            {
                label: "No features, check for hub features",
                page: "step14",
            },
        ]
    },
    step12: {
        screenshot: { name: "Step 12", width: "806px" },
        title: "Count the Features",
        bullets: [
            { text: "Count all the features the user has on the page (for Snap/RAW, anything over 20 is considered 'many')." },
            { text: "Take note of the date of the latest feature." },
        ],
        previousStep: "step11",
        nextSteps: [
            {
                label: "Next",
                page: "step13",
            },
        ]
    },
    step13: {
        screenshot: { name: "Step 13", width: "806px" },
        title: "Return to Feature Logging",
        bullets: [
            { text: "Check the box to show the user has features on page" },
            { text: "Enter the date of the last feature and count of features (for Snap, repeat for RAW feature count)" },
            { text: "If the user has had a feature too recently for the page, check the 'Too soon to feature user'. The feature will get a red tag.", screenshot: { name: "Step 13a", width: "806px" } },
        ],
        previousStep: "step12",
        nextSteps: [
            {
                label: "User recently featured, select next candidate",
                page: "step10",
            },
            {
                label: "Check hub features",
                page: "step14",
            },
        ]
    },
    step14: {
        screenshot: { name: "Step 14", width: "806px" },
        title: "Time to Check User's Hub Features",
        bullets: [
            { text: "To check the user's features, click the 'Copy tag' button for the hub features." },
        ],
        previousStep: "step13",
        nextSteps: [
            {
                label: "Next",
                page: "step15",
            },
        ]
    },
    step15: {
        screenshot: { name: "Step 15", width: "806px" },
        title: "Return to VERO",
        bullets: [
            { text: "Go to the Search and paste the hub tag in the search box and switch to 'Hashtags'." },
        ],
        previousStep: "step14",
        nextSteps: [
            {
                label: "User has hub features",
                page: "step16",
            },
            {
                label: "No hub features, more candidates",
                page: "step10",
            },
            {
                label: "No more candidates, determine 3 candidates to feature",
                page: "step18",
            },
        ]
    },
    step16: {
        screenshot: { name: "Step 16", width: "806px" },
        title: "Count the Hub Features",
        bullets: [
            { text: "Count all the features the user has on the hub (for Snap/RAW, anything over 20 is considered 'many')." },
            { text: "Take note of the date of the latest feature AND the page it was featured on." },
        ],
        previousStep: "step15",
        nextSteps: [
            {
                label: "Next",
                page: "step17",
            },
        ]
    },
    step17: {
        screenshot: { name: "Step 17", width: "806px" },
        title: "Return to Feature Logging",
        bullets: [
            { text: "Check the box to show the user has features on hub." },
            { text: "Enter the date and page for the last feature and the count of features (for Snap, repeat for RAW feature count)." },
            { text: "If the user has had a feature too recently for the page, check the 'Too soon to feature user'. The feature will get a red tag.", screenshot: { name: "Step 13a", width: "806px" } },
        ],
        previousStep: "step16",
        nextSteps: [
            {
                label: "User recently featured, select next candidate",
                page: "step9",
            },
            {
                label: "More candidates, select next candidate",
                page: "step9",
            },
            {
                label: "No more candidates, determine 3 candidates to feature",
                page: "step18",
            },
        ]
    },
    step18: {
        screenshot: { name: "Step 18", width: "800px" },
        title: "Review the Screenshots and Pick the 3 to Feature",
        bullets: [
            { text: "Use whatever method you use to pick your features (I use Adobe Bridge)." },
            { text: "Pick features for image quality, story telling and artistic impression." },
        ],
        previousStep: "step17",
        nextSteps: [
            {
                label: "Next",
                page: "step19",
            },
        ]
    },
    step19: {
        screenshot: { name: "Step 19", width: "806px" },
        title: "Use tineye.com and Your Favorite AI Check to Validate Each Pick",
        bullets: [
            { text: "Check tineye.com to ensure photo belongs to the user and make a decision whether the image was AI generated or not." },
            { text: "If tineye.com shows the image might be stolen (be sure to click the links to check who posted the matches), use the drop-down and pick 'matches found'. The feature will get a red tag.", screenshot: { name: "Step 19a", width: "806px" } },
            { text: "If you determine the photo was AI generated and your page doesn't allow AI, use the drop-down and pick 'ai'. The feature will get a red tag.", screenshot: { name: "Step 19b", width: "806px" } },
            { text: "Finally, if the image passes, check the 'Picked as Feature' checkbox. The feature will get a green star.", screenshot: { name: "Step 19c", width: "806px" }}
        ],
        previousStep: "step18",
        nextSteps: [
            {
                label: "Repeat for other picks",
                page: "step19",
            },
            {
                label: "Next",
                page: "step20",
            },
        ]
    },
    step20: {
        screenshot: { name: "Step 20", width: "806px" },
        title: "Create a Personal Message for the Feature (optional)",
        bullets: [
            { text: "When to pick a feature entry to be featured, a second button will appear to edit the personal message." },
            { text: "Click that button if you will be adding a personal message.", screenshot: { name: "Step 20a", width: "806px" } },
            { text: "In the editor, add the personal message for the feature (this will be combined with the personal message template in the app settings).", screenshot: { name: "Step 20b", width: "806px" } },
            { text: "To change the personal message template, choose 'Settings...' from the app menu (or on macOS, use cmd+,)", link: "settings" },
            { text: "Click Close for now." }
        ],
        previousStep: "step19",
        nextSteps: [
            {
                label: "Repeat for other picks",
                page: "step20",
            },
            {
                label: "Next",
                page: "step21",
            },
        ]
    },
    step21: {
        screenshot: { name: "Step 21", width: "806px" },
        title: "Time to Prepare the Scripts for the Feature",
        bullets: [
            { text: "In the feature list, select the first/next feature and click 'Open Vero Scripts'." },
            { text: "The Vero Scripts app will launch - on Windows, it's a bit clunky as it launches a new copy from the ClickOnce installer each time." },
            { text: "On Windows, if the Vero Scripts app fails to load, check you Internet connection and try again. It's a bit flaky, but should work eventually." },
        ],
        previousStep: "step20",
        nextSteps: [
            {
                label: "Next",
                page: "step22",
            },
        ]
    },
    step22: {
        screenshot: { name: "Step 22", width: "806px" },
        title: "Use Vero Scripts as Normal",
        bullets: [
            { text: "When Vero Scripts is launched from the Feature Logging app, it should populate everything it can from the Feature Logging entry." },
            { text: "Verify the 'Page staff level' since that was not entered in the Feature Logging app." },
            { text: "Page, user, level, feature options, the scripts, the new membership should all be populated!" },
            { text: "Feature the photo using the three (or four) scripts like before." },
        ],
        previousStep: "step21",
        nextSteps: [
            {
                label: "Not the last pick, repeat for each pick",
                page: "step21",
            },
            {
                label: "Done featuring",
                page: "step23",
            },
        ]
    },
    step23: {
        screenshot: { name: "Step 20a", width: "806px" },
        title: "Return to the Feature Logging app",
        bullets: [
            { text: "For each picked candidate, click 'Edit personal message' again." },
            { text: "Click 'Copy full text' to copy the message to the clipboard.", screenshot: { name: "Step 20b", width: "806px" } },
        ],
        previousStep: "step22",
        nextSteps: [
            {
                label: "Next",
                page: "step24",
            },
        ]
    },
    step24: {
        screenshot: { name: "Step 24", width: "806px" },
        title: "Return to VERO",
        bullets: [
            { text: "Return to VERO and switch to your own account, find the feature and add the comment." },
            { text: "Repeat for each pick." },
            { text: "Once you are done, click 'Save log...' and save the log file (a JSON text file)." },
            { text: "Then, click 'Save report...' and save a report file (a plain text file)." },
            { text: "Go have a coffee, you're done!" },
        ],
        previousStep: "step22",
        nextSteps: [
            {
                label: "Start over...",
                page: "step1",
            },
        ]
    },
    settings: {
        screenshot: { name: "Settings", width: "806px" },
        title: "Feature Logging app settings",
        bullets: [
            { text: "If you want to include the hash ('#') in the tags, check the 'Include hash' checkbox." },
            { text: "Use the two editors to edit the template for your personal messages, the legend shows what the %%xxx%% placeholders are used for." },
            { text: "Click 'Close' to return to the app." },
        ],
        nextSteps: [
            {
                label: "return",
                page: "step20",
            },
        ]
    }
};
