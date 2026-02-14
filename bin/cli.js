#!/usr/bin/env node

/**
 * CLAWrity CLI Installer
 *
 * Interactive setup wizard for installing the CLAWrity OpenClaw skill.
 * Run with: npx clawrity@latest
 *
 * Steps:
 *   1. Check Prerequisites (OpenClaw CLI, workspace directory)
 *   2. Prompt for fal.ai API Key
 *   3. Select Neurodivergent Profile (ADHD / Autism / AuDHD)
 *   4. Copy Skill Files to OpenClaw Workspace
 *   5. Update OpenClaw Configuration
 *   6. Inject Companion Persona into SOUL.md
 *   7. Print Summary and Usage Examples
 */

const fs = require("fs");
const path = require("path");
const readline = require("readline");
const { execSync } = require("child_process");

// =========================================================================
// Constants
// =========================================================================

const VERSION = "0.1.2";
const SKILL_NAME = "clawrity";

// OpenClaw workspace paths
const HOME = process.env.HOME || process.env.USERPROFILE || "~";
const OPENCLAW_DIR = path.join(HOME, ".openclaw");
const WORKSPACE_DIR = path.join(OPENCLAW_DIR, "workspace");
const SKILLS_DIR = path.join(WORKSPACE_DIR, "skills");
const SOUL_FILE = path.join(WORKSPACE_DIR, "SOUL.md");
const CONFIG_FILE = path.join(OPENCLAW_DIR, "openclaw.json");

// Paths within the npx package
const PKG_ROOT = path.resolve(__dirname, "..");
const PKG_SKILL = path.join(PKG_ROOT, "skill");
const PKG_SCRIPTS = path.join(PKG_ROOT, "scripts");
const PKG_TEMPLATES = path.join(PKG_ROOT, "templates");

// =========================================================================
// UI Helpers
// =========================================================================

const BOLD = "\x1b[1m";
const RED = "\x1b[31m";
const GREEN = "\x1b[32m";
const YELLOW = "\x1b[33m";
const BLUE = "\x1b[34m";
const MAGENTA = "\x1b[35m";
const CYAN = "\x1b[36m";
const RESET = "\x1b[0m";

function banner() {
    console.log(`
${MAGENTA}${BOLD}
   ██████╗██╗      █████╗ ██╗    ██╗██████╗ ██╗████████╗██╗   ██╗
  ██╔════╝██║     ██╔══██╗██║    ██║██╔══██╗██║╚══██╔══╝╚██╗ ██╔╝
  ██║     ██║     ███████║██║ █╗ ██║██████╔╝██║   ██║    ╚████╔╝
  ██║     ██║     ██╔══██║██║███╗██║██╔══██╗██║   ██║     ╚██╔╝
  ╚██████╗███████╗██║  ██║╚███╔███╔╝██║  ██║██║   ██║      ██║
   ╚═════╝╚══════╝╚═╝  ╚═╝ ╚══╝╚══╝ ╚═╝  ╚═╝╚═╝   ╚═╝      ╚═╝
${RESET}
  ${CYAN}Neurodivergent Support Companion for OpenClaw${RESET}
  ${BLUE}v${VERSION}${RESET}
  `);
}

function logStep(step, total, message) {
    console.log(`\n${BLUE}[${step}/${total}]${RESET} ${BOLD}${message}${RESET}`);
}

function logInfo(msg) {
    console.log(`  ${BLUE}ℹ${RESET}  ${msg}`);
}

function logSuccess(msg) {
    console.log(`  ${GREEN}✓${RESET}  ${msg}`);
}

function logWarn(msg) {
    console.log(`  ${YELLOW}⚠${RESET}  ${msg}`);
}

function logError(msg) {
    console.log(`  ${RED}✗${RESET}  ${msg}`);
}

// =========================================================================
// Prompt Helper
// =========================================================================

function createPrompt() {
    return readline.createInterface({
        input: process.stdin,
        output: process.stdout,
    });
}

function ask(rl, question) {
    return new Promise((resolve) => {
        rl.question(`  ${CYAN}?${RESET}  ${question} `, (answer) => {
            resolve(answer.trim());
        });
    });
}

function askChoice(rl, question, choices) {
    return new Promise(async (resolve) => {
        console.log(`\n  ${CYAN}?${RESET}  ${question}\n`);
        choices.forEach((choice, i) => {
            console.log(`     ${BOLD}${i + 1}.${RESET} ${choice.label}`);
            if (choice.description) {
                console.log(`        ${BLUE}${choice.description}${RESET}`);
            }
        });
        console.log();

        const answer = await ask(rl, `Choose (1-${choices.length}):`);
        const index = parseInt(answer, 10) - 1;

        if (index >= 0 && index < choices.length) {
            resolve(choices[index]);
        } else {
            logWarn(`Invalid choice. Defaulting to: ${choices[0].label}`);
            resolve(choices[0]);
        }
    });
}

// =========================================================================
// File Utilities
// =========================================================================

function ensureDir(dirPath) {
    if (!fs.existsSync(dirPath)) {
        fs.mkdirSync(dirPath, { recursive: true });
    }
}

function copyDirRecursive(src, dest) {
    ensureDir(dest);
    const entries = fs.readdirSync(src, { withFileTypes: true });

    for (const entry of entries) {
        const srcPath = path.join(src, entry.name);
        const destPath = path.join(dest, entry.name);

        if (entry.isDirectory()) {
            copyDirRecursive(srcPath, destPath);
        } else {
            fs.copyFileSync(srcPath, destPath);
        }
    }
}

function fileExists(filePath) {
    return fs.existsSync(filePath);
}

function readFile(filePath) {
    return fs.readFileSync(filePath, "utf-8");
}

function writeFile(filePath, content) {
    fs.writeFileSync(filePath, content, "utf-8");
}

// =========================================================================
// Step 1: Check Prerequisites
// =========================================================================

function checkPrerequisites() {
    logStep(1, 7, "Checking prerequisites");

    // Check OpenClaw directory
    if (!fileExists(OPENCLAW_DIR)) {
        logError(`OpenClaw directory not found at: ${OPENCLAW_DIR}`);
        logError("Install OpenClaw first: https://docs.openclaw.ai");
        logInfo("Run: npm install -g openclaw");
        return false;
    }
    logSuccess(`OpenClaw directory found: ${OPENCLAW_DIR}`);

    // Check workspace
    if (!fileExists(WORKSPACE_DIR)) {
        logWarn(`Workspace directory not found. Creating: ${WORKSPACE_DIR}`);
        ensureDir(WORKSPACE_DIR);
    }
    logSuccess(`Workspace ready: ${WORKSPACE_DIR}`);

    // Check OpenClaw CLI (optional, non-blocking)
    try {
        execSync("openclaw --version", { stdio: "pipe" });
        logSuccess("OpenClaw CLI is available");
    } catch {
        logWarn("OpenClaw CLI not found in PATH (non-blocking)");
        logInfo("The skill will still work via direct Gateway API calls.");
    }

    // Check skills directory
    ensureDir(SKILLS_DIR);
    logSuccess(`Skills directory ready: ${SKILLS_DIR}`);

    return true;
}

// =========================================================================
// Step 2: fal.ai API Key
// =========================================================================

async function promptFalKey(rl) {
    logStep(2, 7, "Setting up fal.ai API key (optional)");

    logInfo("CLAWrity can generate companion visuals using fal.ai (Grok Imagine).");
    logInfo("This is optional — CLAWrity works in text-only mode without it.");
    logInfo("Get a key at: https://fal.ai/dashboard/keys\n");

    // Check if already set in environment
    if (process.env.FAL_KEY) {
        logSuccess("FAL_KEY already set in environment");
        return process.env.FAL_KEY;
    }

    const key = await ask(rl, "Enter your fal.ai API key (or press Enter to skip):");

    if (!key) {
        logInfo("No API key provided — CLAWrity will run in text-only mode.");
        logInfo("You can add it later in openclaw.json or your .env file.");
        return null;
    }

    logSuccess("API key received — image generation enabled");
    return key;
}

// =========================================================================
// Step 3: Select Profile
// =========================================================================

async function selectProfile(rl) {
    logStep(3, 7, "Selecting neurodivergent profile");

    logInfo("Choose the profile that best fits your experience.\n");

    const choice = await askChoice(rl, "Which profile resonates with you?", [
        {
            label: "ADHD",
            value: "adhd-default",
            description:
                "Focus on task initiation, time blindness, dopamine-friendly micro-steps",
        },
        {
            label: "Autism",
            value: "autism-default",
            description:
                "Focus on routine support, sensory management, social scripting",
        },
        {
            label: "AuDHD (ADHD + Autism)",
            value: "audhd-default",
            description:
                "Handles the unique contradictions of having both — novelty vs routine, impulsivity vs processing time",
        },
    ]);

    logSuccess(`Selected profile: ${choice.label}`);
    return choice;
}

// =========================================================================
// Step 4: Copy Skill Files
// =========================================================================

function copySkillFiles() {
    logStep(4, 7, "Installing skill files");

    const targetDir = path.join(SKILLS_DIR, SKILL_NAME);

    // Check if already installed
    if (fileExists(targetDir)) {
        logWarn(`Skill directory already exists: ${targetDir}`);
        logInfo("Overwriting with latest version...");
    }

    // Copy skill directory
    copyDirRecursive(PKG_SKILL, targetDir);
    logSuccess(`Skill definition copied to: ${targetDir}`);

    // Copy scripts alongside skill
    const scriptsTarget = path.join(targetDir, "scripts");
    copyDirRecursive(PKG_SCRIPTS, scriptsTarget);
    logSuccess(`Scripts copied to: ${scriptsTarget}`);

    return targetDir;
}

// =========================================================================
// Step 5: Update Configuration
// =========================================================================

function updateConfig(falKey, profileChoice) {
    logStep(5, 7, "Updating OpenClaw configuration");

    let config = {};

    // Load existing config if present
    if (fileExists(CONFIG_FILE)) {
        try {
            const raw = readFile(CONFIG_FILE);
            config = JSON.parse(raw);
            logInfo("Existing openclaw.json found — merging configuration");
        } catch {
            logWarn("Could not parse existing openclaw.json — creating fresh config");
            config = {};
        }
    }

    // Ensure nested structure
    if (!config.skills) config.skills = {};
    if (!config.skills.entries) config.skills.entries = {};
    if (!config.skills.entries[SKILL_NAME]) {
        config.skills.entries[SKILL_NAME] = {};
    }

    const skillConfig = config.skills.entries[SKILL_NAME];

    // Set skill enabled
    skillConfig.enabled = true;
    skillConfig.profile = profileChoice.value;

    // Set environment variables
    if (!skillConfig.env) skillConfig.env = {};
    if (falKey) {
        skillConfig.env.FAL_KEY = falKey;
    }

    // Write config
    writeFile(CONFIG_FILE, JSON.stringify(config, null, 2));
    logSuccess(`Configuration saved to: ${CONFIG_FILE}`);

    return !!skillConfig.env.FAL_KEY;
}

// =========================================================================
// Step 6: Inject Companion Persona
// =========================================================================

function injectPersona(profileChoice) {
    logStep(6, 7, "Injecting companion persona");

    // Read soul injection template
    const injectionPath = path.join(PKG_TEMPLATES, "soul-injection.md");
    if (!fileExists(injectionPath)) {
        logError(`Soul injection template not found: ${injectionPath}`);
        return;
    }
    const injection = readFile(injectionPath);

    // Read profile
    const profilePath = path.join(
        PKG_TEMPLATES,
        "profiles",
        `${profileChoice.value}.md`
    );
    let profileContent = "";
    if (fileExists(profilePath)) {
        profileContent = "\n\n" + readFile(profilePath);
        logSuccess(`Profile loaded: ${profileChoice.label}`);
    } else {
        logWarn(`Profile not found: ${profilePath}`);
    }

    // Build persona block
    const MARKER_START = "<!-- CLAWRITY_START -->";
    const MARKER_END = "<!-- CLAWRITY_END -->";
    const personaBlock = `${MARKER_START}\n${injection}${profileContent}\n${MARKER_END}`;

    // Read or create SOUL.md
    let soulContent = "";
    if (fileExists(SOUL_FILE)) {
        soulContent = readFile(SOUL_FILE);
        logInfo("Existing SOUL.md found");

        // Remove old injection if present
        const startIdx = soulContent.indexOf(MARKER_START);
        const endIdx = soulContent.indexOf(MARKER_END);
        if (startIdx !== -1 && endIdx !== -1) {
            soulContent =
                soulContent.substring(0, startIdx) +
                soulContent.substring(endIdx + MARKER_END.length);
            logInfo("Replacing previous CLAWrity persona injection");
        }
    }

    // Append persona
    soulContent = soulContent.trimEnd() + "\n\n" + personaBlock + "\n";
    writeFile(SOUL_FILE, soulContent);
    logSuccess(`Companion persona injected into: ${SOUL_FILE}`);
}

// =========================================================================
// Step 7: Summary
// =========================================================================

function printSummary(profileChoice, isImageGenEnabled) {
    logStep(7, 7, "Installation complete!");

    console.log(`
  ${GREEN}${BOLD}CLAWrity is ready! 🦞🧠${RESET}

  ${BOLD}What was installed:${RESET}
  ${GREEN}•${RESET} Skill definition → ${SKILLS_DIR}/${SKILL_NAME}/
  ${GREEN}•${RESET} Companion persona → ${SOUL_FILE}
  ${GREEN}•${RESET} Configuration → ${CONFIG_FILE}
  ${GREEN}•${RESET} Profile: ${CYAN}${profileChoice.label}${RESET}
  ${GREEN}•${RESET} Image generation: ${isImageGenEnabled ? `${GREEN}enabled${RESET}` : `${YELLOW}text-only (no FAL_KEY)${RESET}`}

  ${BOLD}Try these messages with your OpenClaw agent:${RESET}

  ${YELLOW}Body Double:${RESET}
    "I can't start this task, sit with me"
    "Body double me while I write this email"

  ${YELLOW}Task Breakdown:${RESET}
    "I'm overwhelmed, break down cleaning my apartment"
    "I have too much to do, help me simplify"

  ${YELLOW}Transitions:${RESET}
    "I finished studying, help me switch to cooking"
    "I can't move on from this task"

  ${YELLOW}Sensory Break:${RESET}
    "Everything is too loud, I need a break"
    "Sensory overload, help me calm down"

  ${YELLOW}Social Scripts:${RESET}
    "How do I tell my boss I need a day off?"
    "Help me respond to this awkward text"

  ${YELLOW}Celebration:${RESET}
    "I finally submitted my application!"
    "I did it! I made the phone call!"

  ${BLUE}${BOLD}Need help?${RESET}
  ${BLUE}→${RESET} https://github.com/SudheerNaraharisetty/CLAWrity
  `);
}

// =========================================================================
// Main
// =========================================================================

async function main() {
    const rl = createPrompt();

    try {
        banner();

        // Step 1: Prerequisites
        const prereqsOk = checkPrerequisites();
        if (!prereqsOk) {
            logError("\nPrerequisites check failed. Please install OpenClaw first.");
            rl.close();
            process.exit(1);
        }

        // Step 2: fal.ai key
        const falKey = await promptFalKey(rl);

        // Step 3: Profile selection
        const profileChoice = await selectProfile(rl);

        // Step 4: Copy files
        copySkillFiles();

        // Step 5: Config
        const isImageGenEnabled = updateConfig(falKey, profileChoice);

        // Step 6: Persona injection
        injectPersona(profileChoice);

        // Step 7: Summary
        printSummary(profileChoice, isImageGenEnabled);

        rl.close();
    } catch (error) {
        logError(`\nInstallation failed: ${error.message}`);
        rl.close();
        process.exit(1);
    }
}

main();
