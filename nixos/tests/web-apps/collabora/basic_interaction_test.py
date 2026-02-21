import os
import sys
import tempfile
import time
from playwright.sync_api import sync_playwright, TimeoutError as PlaywrightTimeoutError
import openpyxl

TEST_CONTENT = "Welcome to Nixos"


def run_test():
    is_headful = os.getenv("HEADFUL") == "1"
    video_dir = "/tmp/videos/"
    os.makedirs(video_dir, exist_ok=True)

    with sync_playwright() as p:
        browser = p.chromium.launch(headless=not is_headful)

        # Use a longer timeout for slow environments like CI
        timeout = 90000
        context = browser.new_context(
            accept_downloads=True, record_video_dir=video_dir
        )
        context.set_default_timeout(timeout)
        page = context.new_page()

        print("Log in")
        page.goto("http://localhost:8180/")
        page.locator("#user").fill("root")
        page.locator("#password").fill("a")
        page.locator("button[type='submit']").click()

        print("Create spreadsheet")
        page.goto("http://localhost:8180/apps/files/files")

        # Handle potential "Welcome" modal (e.g. first run wizard)
        try:
            # The modal might take a moment to appear, but we don't want to wait too long if it doesn't
            page.get_by_role("button", name="Close").click(timeout=10000)
            print("Closed welcome modal")
        except (PlaywrightTimeoutError, Exception):
            print("No welcome modal found or it disappeared")

        # Wait for "New" button to be visible and actionable
        new_btn = page.get_by_role("button", name="New")
        new_btn.wait_for(state="visible")
        new_btn.click()
        
        page.get_by_role("menuitem", name="New spreadsheet").click()
        page.get_by_role("button", name="Create").click()

        print("Waiting for iframe")
        page.wait_for_selector("iframe", state="visible")
        iframe = page.frame_locator("iframe")

        print("Waiting for Collabora UI to load")
        # Wait for the main toolbar to be visible
        iframe.locator("#toolbar-up").wait_for(state="visible", timeout=timeout)
        
        # Give a small grace period for the canvas to be ready for input
        time.sleep(2)

        print("Selecting text layer")
        text_layer = iframe.locator(".ui-custom-textarea-text-layer")
        text_layer.wait_for(state="visible")
        text_layer.click()
        
        # Ensure the editor has focus
        time.sleep(1)

        print(f"Typing content: {TEST_CONTENT}")
        page.keyboard.type(TEST_CONTENT, delay=100)
        page.keyboard.press("Enter")
        
        # Wait for the changes to be registered in the UI
        time.sleep(2)

        print("Saving")
        save_btn = iframe.get_by_role("button", name="Save")
        save_btn.wait_for(state="visible")
        save_btn.click()
        
        # Wait for save operation to complete (Collabora shows status in the bottom)
        # For now, a small sleep is safer as the status bar text is hard to target reliably
        time.sleep(3)

        print("Closing document")
        # Use force=True as the button might be technically "hidden" or covered
        iframe.get_by_role("button", name="Close document").click(force=True)
        
        # Wait until we are back in the files app
        print("Waiting for redirect back to files app")
        page.wait_for_url("**/apps/files/**", timeout=timeout)

        def verify_remote_file() -> str:
            # We use the authenticated context to request the file via WebDAV
            response = context.request.get(
                "http://localhost:8180/remote.php/webdav/New%20spreadsheet.xlsx"
            )
            if not response.ok:
                return f"File unavailable (status {response.status})"

            with tempfile.NamedTemporaryFile(delete=False, suffix=".xlsx") as tmp:
                tmp.write(response.body())
                download_path = tmp.name

            try:
                wb = openpyxl.load_workbook(download_path)
                return str(wb.active["A1"].value)
            except Exception as e:
                return f"File corrupt or mid-write: {e}"
            finally:
                if os.path.exists(download_path):
                    os.remove(download_path)

        # Longer verification timeout as sync can be slow
        timeout_seconds = 60
        start_time = time.time()
        is_successful = False
        last_value = None

        print("Verifying content via WebDAV")
        while time.time() - start_time < timeout_seconds:
            last_value = verify_remote_file()

            if last_value == TEST_CONTENT:
                print("Content verified successfully")
                is_successful = True
                break
            
            print(f"Current value: '{last_value}', retrying...")
            time.sleep(2)

        if not is_successful:
            print(
                f"Error: Backend failed to sync within {timeout_seconds} seconds. Last seen value: '{last_value}'"
            )
            sys.exit(1)

        context.close()
        browser.close()


if __name__ == "__main__":
    run_test()
