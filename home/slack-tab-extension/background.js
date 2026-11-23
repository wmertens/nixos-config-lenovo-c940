// Each profile connects to the slack-tab host; the host pings us when the global hotkey fires.
const SLACK = 'https://app.slack.com/client/T09HPBP3PD1/*'

function connect() {
  const port = chrome.runtime.connectNative('wout.slack_tab')
  port.onMessage.addListener(async () => {
    const [tab] = await chrome.tabs.query({ url: SLACK })
    if (!tab) return
    await chrome.tabs.update(tab.id, { active: true })
    await chrome.windows.update(tab.windowId, { focused: true, drawAttention: true })
  })
  port.onDisconnect.addListener(() => setTimeout(connect, 5000))
}

connect()
// the service worker wakes on startup/install; the open native port keeps it alive
