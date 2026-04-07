# Bot with Automatic Building Example

This example demonstrates **automatic bot building** - a key feature that makes your Lex bot ready for testing immediately after deployment, without manual intervention.

## What is Bot Building?

In AWS Lex V2, after creating/updating a bot, you must **build** each locale before testing. Building:
- Compiles your intents, slots, and utterances into an ML model
- Validates your bot configuration
- Prepares the bot for testing and production use

**Without automatic building:**
1. Run `terraform apply`
2. Go to AWS Console
3. Click "Build" for each locale
4. Wait 1-2 minutes
5. Finally, test your bot

**With automatic building (this example):**
1. Run `terraform apply`
2. Bot is automatically built and ready! ✅

## What This Example Shows

- ✅ Automatic bot building after deployment
- ✅ Wait for build completion (ensures bot is ready)
- ✅ Multiple intents with slots
- ✅ Custom slot types
- ✅ Build timeout configuration
- ✅ Build status tracking

## Features in This Example

### Bot Configuration
- **2 intents**: BookAppointment, CheckAppointment
- **1 custom slot type**: AppointmentType
- **3 slots**: AppointmentType, Date, Time
- **Voice enabled**: Joanna voice

### Building Configuration
```hcl
auto_build_bot_locales    = true   # Enable automatic building
wait_for_build_completion = true   # Wait for build to finish
build_timeout_seconds     = 300    # 5 minutes timeout
```

## Prerequisites

1. **AWS Account** with Lex permissions
2. **Terraform** >= 1.0
3. **jq** installed (for slot priorities)
4. **AWS CLI** configured

## Usage

### Step 1: Navigate to Example
```bash
cd examples/lex-with-building
```

### Step 2: Initialize
```bash
terraform init
```

### Step 3: Review Plan
```bash
terraform plan
```

You'll see:
- Bot resources
- Locale resources
- Intent and slot resources
- **Build trigger resources** (new!)

### Step 4: Apply
```bash
terraform apply
```

**What happens:**
1. Bot and locales created (~10s)
2. Intents and slots created (~5s)
3. **Bot build triggered** (~1-2 minutes)
4. Build completion verified
5. Bot ready for testing!

Total time: ~2-3 minutes (vs manual: 5+ minutes)

### Step 5: Test the Bot

The bot is now ready to test immediately!

**Option A: AWS Console**
1. Go to [Lex V2 Console](https://console.aws.amazon.com/lexv2/)
2. Find bot: **AutoBuildBot**
3. Status shows: **Built** ✅
4. Click **Test**
5. Try: "I want to book an appointment"

**Option B: AWS CLI**
```bash
aws lexv2-runtime recognize-text \
  --bot-id $(terraform output -raw bot_id) \
  --bot-alias-id TSTALIASID \
  --locale-id en_US \
  --session-id test-session-1 \
  --text "I want to book an appointment"
```

## Configuration Options

### Fast Mode (Development)

For faster iterations during development:
```hcl
auto_build_bot_locales    = true
wait_for_build_completion = false  # Don't wait
build_timeout_seconds     = 300
```

**Behavior:**
- Build is triggered
- Terraform doesn't wait
- Continue working while build happens in background
- ⚡ Faster `terraform apply`

### Production Mode (Recommended)

For production deployments:
```hcl
auto_build_bot_locales    = true
wait_for_build_completion = true   # Wait for completion
build_timeout_seconds     = 600    # 10 minutes for complex bots
```

**Behavior:**
- Build is triggered
- Terraform waits until complete
- Ensures bot is ready before proceeding
- ✅ Safer deployments

### Manual Building

To disable automatic building:
```hcl
auto_build_bot_locales = false
```

**When to use:**
- Development/experimentation
- Frequent small changes
- Want to control when to build

## Build Process Details

### What Happens During Build