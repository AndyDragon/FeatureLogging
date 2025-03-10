import React from "react";
import "./App.css";
import {
    Button,
    Display,
    DrawerBody,
    DrawerHeader,
    DrawerHeaderTitle,
    Image,
    InlineDrawer,
    Title3,
    makeStyles,
    shorthands,
    teamsDarkTheme,
} from "@fluentui/react-components";
import { Dismiss24Regular, PanelLeftExpand24Regular } from "@fluentui/react-icons";
import {
    applicationName,
    deploymentWebLocation,
    hasTutorial,
    versionLocation,
    showMacInfo,
    macReleaseNotesLocation,
    showWindowsInfo,
    windowsReleaseNotesLocation,
    showIosInfo,
    iosReleaseNotesLocation,
    PlatformLocation,
    showAndroidInfo,
    androidReleaseNotesLocation,
    platformString,
} from "./config";
import About from "./About";
import General from "./General";
import ReleaseNotes from "./ReleaseNotes";
import Support from "./Support";
import { BrowserRouter as Router, Route, Routes, Link } from "react-router-dom";
import Tutorial from "./Tutorial";

const useStyles = makeStyles({
    cleanLink: {
        ...shorthands.textDecoration("none"),
        color: "CornflowerBlue",
        "&:hover": {
            ...shorthands.textDecoration("underline"),
            color: "LightBlue",
        },
    },
});

function App() {
    const [open, setOpen] = React.useState(true);

    const styles = useStyles();

    React.useEffect(() => {
        document.title = applicationName + " portal";
    }, []);

    return (
        <div className="App">
            <Router basename={deploymentWebLocation}>
                <InlineDrawer open={open} position="start">
                    <DrawerHeader style={{ backgroundColor: teamsDarkTheme.colorBrandBackground }}>
                        <DrawerHeaderTitle
                            action={
                                <Button
                                    appearance="subtle"
                                    aria-label="Close"
                                    icon={<Dismiss24Regular />}
                                    onClick={() => setOpen(false)}
                                />
                            }
                        >
                            <div style={{ height: "48px" }}>
                                &nbsp;
                            </div>
                        </DrawerHeaderTitle>
                    </DrawerHeader>
                    <DrawerBody style={{ marginTop: "40px"}}>
                        <nav>
                            <div style={{ display: "flex", flexDirection: "column", marginTop: "0px" }}>
                                <Link className={styles.cleanLink} style={{ fontSize: "20pt", marginTop: "40px" }} to="/">
                                    About
                                </Link>
                            </div>
                            <div style={{ display: "flex", flexDirection: "column", marginTop: "0px" }}>
                                <Link className={styles.cleanLink} style={{ fontSize: "20pt", marginTop: "40px" }} to="/support">
                                    Support
                                </Link>
                            </div>
                            {(showMacInfo !== PlatformLocation.DoNotShow) && (
                            <div style={{ display: "flex", flexDirection: "column", marginTop: "32px" }}>
                                <Title3>{platformString["macOS"]}</Title3>
                                <div style={{ marginLeft: "20px", display: "flex", flexDirection: "column" }}>
                                    <Link className={styles.cleanLink} style={{ fontSize: "15pt", margin: "8px 0 8px 0" }} to="/macInstall">
                                        Install
                                    </Link>
                                    <Link className={styles.cleanLink} style={{ fontSize: "15pt", margin: "8px 0 0 0" }} to="/macReleaseNotes">
                                        Release notes
                                    </Link>
                                </div>
                            </div>
                            )}
                            {(showIosInfo !== PlatformLocation.DoNotShow) && (
                            <div style={{ display: "flex", flexDirection: "column", marginTop: "32px" }}>
                                <Title3>{platformString["iOS"]}</Title3>
                                <div style={{ marginLeft: "20px", display: "flex", flexDirection: "column" }}>
                                    <Link className={styles.cleanLink} style={{ fontSize: "15pt", margin: "8px 0 8px 0" }} to="/iosInstall">
                                        Install
                                    </Link>
                                    <Link className={styles.cleanLink} style={{ fontSize: "15pt", margin: "8px 0 0 0" }} to="/iosReleaseNotes">
                                        Release notes
                                    </Link>
                                </div>
                            </div>
                            )}
                            {(showWindowsInfo !== PlatformLocation.DoNotShow) && (
                            <div style={{ display: "flex", flexDirection: "column", marginTop: "32px" }}>
                                <Title3>{platformString["windows"]}</Title3>
                                <div style={{ marginLeft: "20px", display: "flex", flexDirection: "column" }}>
                                    <Link className={styles.cleanLink} style={{ fontSize: "15pt", margin: "8px 0 8px 0" }} to="/windowsInstall">
                                        Install
                                    </Link>
                                    <Link className={styles.cleanLink} style={{ fontSize: "15pt", margin: "8px 0 0 0" }} to="/windowsReleaseNotes">
                                        Release notes
                                    </Link>
                                </div>
                            </div>
                            )}
                            {(showAndroidInfo !== PlatformLocation.DoNotShow) && (
                            <div style={{ display: "flex", flexDirection: "column", marginTop: "32px" }}>
                                <Title3>{platformString["android"]}</Title3>
                                <div style={{ marginLeft: "20px", display: "flex", flexDirection: "column" }}>
                                    <Link className={styles.cleanLink} style={{ fontSize: "15pt", margin: "8px 0 8px 0" }} to="/androidInstall">
                                        Install
                                    </Link>
                                    <Link className={styles.cleanLink} style={{ fontSize: "15pt", margin: "8px 0 0 0" }} to="/androidReleaseNotes">
                                        Release notes
                                    </Link>
                                </div>
                            </div>
                            )}
                            {hasTutorial && (
                                <div style={{ display: "flex", flexDirection: "column", marginTop: "40px" }}>
                                    <Link className={styles.cleanLink} style={{ fontSize: "20pt" }} to="/tutorial">
                                        Tutorial
                                    </Link>
                                </div>
                            )}
                        </nav>
                    </DrawerBody>
                </InlineDrawer>
                {open ? (
                    <></>
                ) : (
                    <Button
                        appearance="subtle"
                        aria-label="Open"
                        icon={<PanelLeftExpand24Regular />}
                        onClick={() => setOpen(true)}
                    />
                )}
                <div
                    style={{
                        display: "flex",
                        flexDirection: "column",
                        width: "100%",
                        padding: "20px",
                        backgroundColor: teamsDarkTheme.colorNeutralBackground3,
                    }}
                >
                    <div style={{ display: "flex", flexDirection: "row", width: "100%" }}>
                        <Image alt="Application Icon" src={process.env.PUBLIC_URL + "/AppIcon.png"} width={128} height={128} style={{ marginRight: "20px" }} />
                        <Display>{applicationName}</Display>
                    </div>
                    <div
                        style={{
                            width: "calc(100% - 40px)",
                            height: "100%",
                            margin: "20px",
                            overflow: "auto",
                            backgroundColor: teamsDarkTheme.colorNeutralBackground4,
                            borderRadius: "8px",
                        }}
                    >
                        <Routes>
                            <Route path="/" element={(
                                <About
                                    applicationName={applicationName}
                                    versionLocation={versionLocation} />
                            )} />
                            <Route path="/support" element={(
                                <Support
                                    applicationName={applicationName}
                                    versionLocation={versionLocation} />
                            )} />
                            <Route path="/macInstall" element={(
                                <General
                                    applicationName={applicationName}
                                    platform="macOS"
                                    versionLocation={versionLocation} />
                            )} />
                            <Route path="/macReleaseNotes" element={(
                                <ReleaseNotes
                                    applicationName={applicationName}
                                    platform="macOS"
                                    location={macReleaseNotesLocation}
                                    versionLocation={versionLocation}
                                />
                            )} />
                            <Route path="/iosInstall" element={(
                                <General
                                    applicationName={applicationName}
                                    platform="iOS"
                                    versionLocation={versionLocation} />
                            )} />
                            <Route path="/iosReleaseNotes" element={(
                                <ReleaseNotes
                                    applicationName={applicationName}
                                    platform="iOS"
                                    location={iosReleaseNotesLocation}
                                    versionLocation={versionLocation}
                                />
                            )} />
                            <Route path="/windowsInstall" element={(
                                <General
                                    applicationName={applicationName}
                                    platform="windows"
                                    versionLocation={versionLocation} />
                            )} />
                            <Route path="/windowsReleaseNotes" element={(
                                <ReleaseNotes
                                    applicationName={applicationName}
                                    platform="windows"
                                    location={windowsReleaseNotesLocation}
                                    versionLocation={versionLocation}
                                />
                            )} />
                            <Route path="/androidInstall" element={(
                                <General
                                    applicationName={applicationName}
                                    platform="android"
                                    versionLocation={versionLocation} />
                            )} />
                            <Route path="/androidReleaseNotes" element={(
                                <ReleaseNotes
                                    applicationName={applicationName}
                                    platform="android"
                                    location={androidReleaseNotesLocation}
                                    versionLocation={versionLocation}
                                />
                            )} />
                            <Route path="/tutorial" element={(
                                <Tutorial
                                    applicationName={applicationName}
                                    versionLocation={versionLocation}
                                />
                            )} />
                            <Route path="/tutorial/:page" element={(
                                <Tutorial
                                    applicationName={applicationName}
                                    versionLocation={versionLocation}
                                />
                            )} />
                        </Routes>
                    </div>
                </div>
            </Router>
        </div>
    );
}

export default App;
