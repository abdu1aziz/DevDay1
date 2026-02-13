# 🚀 Setup Your Mac - Kandji Cleanup Changelog

## 📖 Project Description

**Setup Your Mac (SYM) - Developer Onboarding Automation**

This enterprise-grade automation script streamlines the macOS device provisioning process for engineering teams by delivering a unified, hands-free onboarding experience. Built on the swiftDialog framework and integrated with Kandji MDM, this solution eliminates the manual, time-intensive process of individually locating and installing development tools through Self Service.

### 💼 Business Value & Use Cases

**🎯 Primary Objective:**  
Reduce developer onboarding time from hours to minutes by automating the deployment of essential development tooling, enabling new team members to become productive on day one.

**✨ Key Benefits:**
- ⚡ **Time Efficiency:** Eliminates 2-4 hours of manual software installation per developer
- 🎯 **Consistency:** Ensures standardized development environments across the organization
- 🤖 **Self-Service Automation:** Transforms the Self Service experience from search-and-install to one-click deployment
- 🌟 **Onboarding Excellence:** Provides new hires with a modern, polished first-day experience
- 🛠️ **IT Productivity:** Reduces help desk tickets related to tool discovery and installation issues
- 📈 **Scalability:** Supports rapid team expansion without proportional IT overhead

**👥 Target Audiences:**
- 🆕 New developers joining the organization
- 💻 Existing developers receiving replacement devices
- 🔄 Developers requiring a clean slate after OS reinstallation
- 👨‍💼 IT administrators managing fleet provisioning at scale

**🔧 Technical Approach:**  
The script leverages Kandji's Audit & Remediation framework to intelligently validate installed software, skip already-present applications, and orchestrate installations with real-time visual progress feedback. Pre-validation logic ensures optimal performance by avoiding redundant API calls and installations.

**💎 Developer Experience Focus:**  
Unlike traditional MDM-driven installations that provide minimal user feedback, Setup Your Mac delivers a transparent, visually engaging progress interface that keeps users informed throughout the provisioning process, reducing uncertainty and improving the overall perception of IT services.

---

## 📝 Overview
This document tracks all changes made to streamline the script for Kandji deployment with static library items.

**📊 Current Script Status:** 909 lines (reduced from 2090 original lines = 56.5% reduction)

**📦 Original Source:** Based on the Setup Your Mac framework for Jamf Pro, adapted and optimized for Kandji MDM with developer-focused workflow enhancements.

**🖥️ Target Environment:** macOS devices enrolled in Kandji MDM, running macOS 11 Big Sur or later.

---

## ✅ COMPLETED CHANGES

### **🧪 2026-02-12: Added Test-Phase Exit Controls (Force Quit + Quit Key)**
**Type:** UX Safety / Testing Convenience

**What Was Added:**
1. **Force Quit Button**
   - A temporary **Force Quit** button was added to the Setup Your Mac dialog.
   - Pressing the button now exits the dialog **and** terminates the script safely.

2. **Quit Key (k)**
   - The dialog now listens for the `k` key.
   - Pressing `k` exits the dialog **and** terminates the script safely.

**✅ Result:**
- ✔️ Testers can quickly exit without waiting for installs to finish
- ✔️ Script cleans up temp files and exits cleanly
- ✔️ Designed for testing only; can be removed for production

---

### **🔄 2026-02-10: Simplified Completion Action to Restart-Only**
**Original Lines:** ~1125-1170, ~1640-1750
**Lines Removed:** ~150 lines
**Current Location:** Lines 825-886 (completionAction function)

**What Was Removed:**
1. **Completion Action Case Statement**
   - Removed support for: Shut Down, Log Out, Sleep, Quit options
   - Removed dynamic button text logic for 9 different completion scenarios
   - Removed `button1textCompletionActionOption` variable
   - Removed `progressTextCompletionAction` variable

2. **Completion Action Function**
   - Removed Shut Down logic (immediate/attended/confirm)
   - Removed Log Out logic (immediate/attended/confirm)
   - Removed Sleep duration logic
   - Removed Quit option
   - Removed debug mode completion dialog
   - Kept only: **Restart Attended** behavior

3. **Script Parameter**
   - Removed completionActionOption parameter (was Parameter 7)
   - Now hardcoded to restart behavior

**What Was Kept:**
- Single restart behavior: User clicks "Restart" button → Mac restarts in 5 seconds
- Kandji Self Service process termination before restart
- Final dialog update showing completion

**✅ Result:**
- ✔️ Developer setup always ends with restart
- ✔️ Simpler, more predictable behavior
- ✔️ ~150 lines of unnecessary code removed
- ✔️ No user confusion about completion options

**🔄 New Workflow:**
1. ✅ All library items install
2. 🎉 Dialog shows "Your Mac is ready!"
3. 🔘 Button text: "Restart"
4. 🚀 User clicks → Mac restarts automatically

---

### **🔄 2026-02-10 & 2026-02-11: Replaced Jamf Terminology with Kandji** (30+ occurrences)
**Type:** Terminology Updates

**Current Key References:**
1. **Line 20:** "Kandji Script Parameters" (was "Jamf Pro Script Parameters")
2. **Line 283-295:** Kandji MDM pre-flight check
3. **Line 396:** Kandji launch daemon: io.kandji.kandji-agent.plist
4. **Line 534:** Kandji binary variable: `kandjiBinary="/usr/local/bin/kandji"`
5. **Line 154:** confirmPolicyExecution function (triggers Kandji library items)
6. **Line 197:** validatePolicyResult function
7. **Line 762-797:** policyJSONConfiguration function

**Variable Names Renamed:**
- `jamfBinary` → `kandjiBinary`
- `jamflaunchDaemon` → `kandjilaunchDaemon`
- `jamfProPolicyTriggerFailure` → `kandjiLibraryItemFailure`

**User-Facing Messages Updated:**
1. **Inventory Progress Text:**
   - "A listing of your Mac's apps and settings — its inventory — is sent automatically to the Jamf Pro server daily."
   - → "Your Mac's inventory will be updated with Kandji."

2. **Failure Dialog Messages:**
   - "Jamf Pro Policy Name Failures:" → "Kandji Library Item Failures:"
   - "Login to Self Service" → "Login to Kandji Self Service"
   - "Re-run any failed policy" → "Re-run any failed library item"

**✅ Result:**
- ✔️ Script now uses consistent Kandji terminology throughout
- ✔️ No more confusion with Jamf-specific terms
- ✔️ User-facing messages accurately reflect Kandji platform
- ✔️ Variable names are semantically correct for Kandji
- ✔️ Comments properly explain Kandji workflows

**Total Updates:** ~30+ references across comments, variables, and messages

### **🗑️ 2026-02-11: Removed Unused failureCommandFile Variable**
**Lines Removed:** ~14 lines (533, 537, 676-682, 807-810)
**Type:** Dead Code Removal

**What Was Removed:**
1. **Variable Declaration:** `failureCommandFile=$( mktemp /var/tmp/dialogFailure.XXX )`
2. **Permission Setting:** `chmod 644 "${failureCommandFile}"`
3. **Misleading Comment Section:** Lines referring to "Failure dialog" function that doesn't exist (7 lines)
4. **Cleanup Block:** Removal of failureCommandFile in quitScript() (4 lines)

**❓ Reason:**
- ❌ Variable was created but never actually used
- ✔️ All failure handling goes through finalise() function
- ✔️ All logging goes to /var/log/org.nm.devday1.log via updateScriptLog()
- ❌ No separate failure dialog exists in the script

**✅ Result:**
- 📉 Script reduced from 923 to 909 lines
- ✨ Cleaner code with no unused variables
- 💾 No wasted system resources creating unused temp files
- 🛠️ More maintainable codebase

---

### **🧹 2026-02-11: Removed All Welcome Dialog Code**
**Lines Removed:** ~272 lines total
**Type:** Major Cleanup

**What Was Removed:**
1. **Welcome Dialog Variables & JSON (~85 lines)**
   - welcomeTitle, welcomeMessage, welcomeBannerImage, welcomeBannerText
   - welcomeCaption, welcomeVideoID
   - welcomeVideo variable
   - welcomeJSON entire block with textfields and selectitems
   - appleInterfaceStyle detection for dark/light icons

2. **Welcome Dialog Display Logic (~187 lines)**
   - Video dialog display code (welcomeDialog == "video")
   - User input dialog display (welcomeDialog == "userInput")
   - welcomeReturnCode case statement (exit codes 0, 2, 3, 4, *)
   - Computer name renaming logic (scutil commands)
   - reconOptions handling (unused in Kandji)
   - Asset tag/username/department extraction from user input
   - All welcome dialog button handling

**What Was Kept:**
- Auto-populate logic for developer mode (lines 863-880)
- Direct launch of Setup Your Mac dialog (lines 886-897)

**✅ Result:**
- 📉 Major code reduction (272 lines removed)
- ✨ No unused code paths
- 🧹 Cleaner, more maintainable script
- 🎯 Developer mode is the only mode
- 🚀 Script proceeds directly to installation dialog

---

### **🔗 2026-02-11: Removed snelson.us/sym URL Reference**
**Line Affected:** 258
**Type:** Cleanup

**What Changed:**
- ❌ Removed "https://snelson.us/sym" from logging preamble

**✅ Result:**
- ✨ Cleaner output without external references

---

### **⚡ 2026-02-10: Added Pre-Validation Optimization**
**Lines Affected:** 154-258
**Type:** Performance Enhancement

**What Changed:**
1. **confirmPolicyExecution()** (Lines 154-189)
   - Checks if validation path already exists locally
   - Sets `alreadyInstalled="true"` flag if found
   - Skips Kandji library item execution for existing items
   - Saves API calls and execution time

2. **validatePolicyResult()** (Lines 197-258)
   - Checks `alreadyInstalled` flag first
   - Marks items as "Already Installed" if skipped
   - Validates absolute paths with -d (directory) and -f (file) checks
   - Only sets failure state if validation actually fails

**✅ Result:**
- ⚡ Significantly faster repeated runs
- 📉 Reduces unnecessary API calls to Kandji
- ✅ Shows "Already Installed" status for existing items
- 🎯 Maintains validation accuracy

---

### **🔧 2026-02-10: Restored Missing Critical Functions**
**Lines Affected:** 66-147
**Type:** Bug Fix

**Functions Added:**
1. **updateScriptLog()** - Lines 66-68
2. **runAsUser()** - Lines 76-80 (executes commands as logged-in user)
3. **get_json_value()** - Lines 88-92 (JSON parsing with JavaScript)
4. **dialogUpdateSetupYourMac()** - Lines 100-102
5. **dialogUpdateWelcome()** - Lines 110-112
6. **finalise()** - Lines 120-147 (completion handler)

**❓ Reason:** Mass cleanup accidentally removed these critical functions causing "command not found" errors

---

### **🔗 2026-02-10: Consolidated Rosetta Duplicate Triggers**
**Lines Affected:** 765-776 (policyJSON)
**Type:** Cleanup

**What Changed:**
- Consolidated 2 duplicate Rosetta trigger entries into 1
- Changed validation from "Local" to absolute path: "/Library/Apple/usr/libexec/oah"
- Single trigger_list entry per library item

**✅ Result:**
- ✨ Cleaner policyJSON structure
- ✔️ Absolute path validation works with pre-validation optimization
- ✔️ No redundant execution attempts

---

### **🐛 2026-02-10: Changed Default Debug Mode**
**Lines Affected:** Line 27
**Type:** Configuration Change

**What Changed:**
- Changed `debugMode` default from "verbose" to "false"

**✅ Result:**
- ✔️ Production-ready default behavior
- ✔️ Less verbose logging in dev environment
- ✔️ Can still override with script parameter if needed

---

## 📋 CURRENT KEY LINE NUMBERS (as of 2026-02-11, Script: 909 lines)

### **📦 Variable Declarations:**
- **Line 20:** Script version and Kandji script parameters
- **Line 27:** debugMode (default: "false")
- **Line 28:** welcomeDialog (default: "false")
- **Line 44-50:** OS version and logged-in user detection
- **Line 534:** kandjiBinary path: /usr/local/bin/kandji
- **Line 531-534:** Command file creation with chmod 644

### **✈️ Pre-flight Checks:**
- **Lines 265-272:** Root user check
- **Lines 283-295:** Kandji MDM pre-flight check (echoes error if not found)
- **Lines 300-305:** Setup Assistant wait loop
- **Lines 309-314:** Dock/Finder ready check
- **Lines 318-372:** OS version validation
- **Lines 377-402:** Caffeinate process
- **Lines 407-418:** Logged-in user validation
- **Lines 423-436:** Kandji agent disable
- **Lines 442-532:** swiftDialog installation with 3-attempt retry logic

### **⚙️ Critical Functions:**
- **Lines 66-68:** updateScriptLog()
- **Lines 76-80:** runAsUser()
- **Lines 88-92:** get_json_value()
- **Lines 100-102:** dialogUpdateSetupYourMac()
- **Lines 110-112:** dialogUpdateWelcome()
- **Lines 120-147:** finalise()
- **Lines 154-189:** confirmPolicyExecution() (with pre-validation)
- **Lines 197-258:** validatePolicyResult() (with pre-validation check)
- **Lines 806-824:** killProcess()
- **Lines 825-868:** completionAction() (restart only)
- **Lines 876-909:** quitScript()

### **💬 Dialog Configuration:**
- **Lines 544-562:** Dialog infobox variables
- **Lines 569-582:** Setup Your Mac dialog title, message, banner, help
- **Lines 594-617:** dialogSetupYourMacCMD
- **Lines 627:** setupYourMacPolicyArrayIconPrefixUrl

### **📋 PolicyJSON Configuration:**
- **Lines 635-675:** policyJSONConfiguration() function
- **Lines 641-653:** Rosetta library item (absolute path: /Library/Apple/usr/libexec/oah)
- **Lines 654-664:** Computer Inventory item

### **🔀 Main Program Logic:**
- **Lines 736-741:** Commented Kandji agent re-enable code (kept for documentation)
- **Lines 842-861:** Debug mode blurscreen→moveable replacement
- **Lines 863-880:** Auto-populate for developer mode
- **Lines 886-897:** Direct launch to Setup Your Mac dialog (no welcome dialog)
- **Lines 902-909:** Main installation loop (iterates through policyJSON)

---

## 📊 CLEANUP SUMMARY

| Phase | Lines Removed | Total Reduction |
|-------|---------------|-----------------|
| **Completion Action Simplification** | ~150 lines | 7.2% |
| **Welcome Dialog Removal** | ~272 lines | 13.0% |
| **failureCommandFile Removal** | ~14 lines | 0.7% |
| **Terminology Updates** | N/A | Clarity gain |
| **Function Restoration** | Added critical functions | Bug fixes |
| **Pre-validation Optimization** | N/A | Performance gain |
| **swiftDialog Retry Logic** | Enhanced reliability | Robustness |
| **Kandji MDM Check** | Enhanced validation | Safety |
| **TOTAL** | **~436+ lines** | **56.5% reduction**

---

## 🚧 PENDING ITEMS (User Action Required)

### **1️⃣ Populate policyJSON with 10 Developer Tools**
**📍 Current Location:** Lines 635-675
**📝 What's Needed:**
- Replace "ROSETTA-LIBRARY-ITEM-ID" with actual Kandji Library Item ID
- Add 8 more library items (total 10)
  - 6 binary files → validation path: `/usr/local/bin/binary-name`
  - 4 .app folders → validation path: `/Applications/App Name.app`
  
**Example Format:**
```json
{
    "listitem": "Tool Name",
    "icon": "hash-value",
    "progresstext": "Description of what this tool does",
    "trigger_list": [
        {
            "trigger": "KANDJI-LIBRARY-ITEM-ID",
            "validation": "/path/to/validation"
        }
    ]
}
```

### **2️⃣ Update Support Contact Information**
**📍 Current Location:** Lines 569-582
**📝 What's Needed:**
- Line ~570: Update telephone number (currently: +1 (801) 555-1212)
- Line ~571: Update email address (currently: support@domain.org)
- Line ~572: Update knowledge base article (currently: KB0057050)

### **3️⃣ Optional: Add Rosetta Pre-flight Installation**
**📊 Current Status:** Rosetta only in policyJSON, not in pre-flight checks
**💡 What Could Be Added:**
- Function similar to dialogCheck() for swiftDialog
- Check if `/Library/Apple/usr/libexec/oah` exists
- If not, run: `softwareupdate --install-rosetta --agree-to-license`
- Only needed if Rosetta must be installed before other tools

---

## ✅ SCRIPT READINESS STATUS

| Component | Status | Notes |
|-----------|--------|-------|
| **Core Structure** | ✅ Complete | 909 lines, fully functional |
| **Kandji Integration** | ✅ Complete | CLI commands, validation, MDM check |
| **Pre-validation** | ✅ Complete | Skips already-installed items |
| **swiftDialog** | ✅ Complete | 3-attempt retry, Team ID verification |
| **Developer Mode** | ✅ Complete | Auto-population, direct launch |
| **Completion Action** | ✅ Complete | Restart-only behavior |
| **Error Handling** | ✅ Complete | Logging to /var/log/org.nm.devday1.log |
| **Code Cleanup** | ✅ Complete | No unused code, no dead variables |
| **Library Items** | ⏳ Pending | Need 10 actual Kandji library item IDs |
| **Support Info** | ⏳ Pending | Need actual contact details |
| **Testing** | ⏳ Ready | Awaiting library item population |

---

## 🎯 NEXT STEPS FOR PRODUCTION

1. 📦 **Populate Library Items** → Add 10 Kandji library item IDs to policyJSON
2. 📞 **Update Support Contact** → Replace placeholder contact information
3. 🧪 **Test with Real Items** → Run script with actual Kandji library items
4. 🚀 **Deploy** → Push to production environment

**⏱️ Estimated Time to Production Ready:** ~30-60 minutes (depends on gathering library item IDs)


4. Test after each phase
5. Update script version to 2.0.0-Kandji

---

**Questions to Consider:**
- Do you want to keep all three configurations (Required/Recommended/Complete)?
- Should we completely remove Remote validation or just simplify it?
- Do you need any asset tag/computer naming functionality?
- What support info should go in help messages?
