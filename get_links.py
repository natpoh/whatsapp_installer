import re
import json
import sys
from playwright.sync_api import sync_playwright

def main():
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        page = browser.new_page()
        print("Navigating to store.rg-adguard.net...")
        page.goto("https://store.rg-adguard.net/")
        
        print("Filling form...")
        page.locator('input[type="text"]').fill('https://apps.microsoft.com/detail/whatsapp/9NKSQGP7F2NH')
        page.locator('input[type="button"], button, input[value="✔"], #btn-submit').first.click()
        
        print("Waiting for results...")
        try:
            page.wait_for_selector('table', timeout=30000)
            page.wait_for_function('document.querySelectorAll("table a").length > 0', timeout=30000)
        except Exception as e:
            print(f"Error waiting for results: {e}")
            page.screenshot(path="error.png")
            sys.exit(1)
            
        print("Extracting links...")
        links = page.locator('table a').element_handles()
        
        download_list = []
        for link in links:
            text = link.inner_text()
            href = link.get_attribute('href')
            
            # Filter for x64 or neutral, exclude blockmap
            text_lower = text.lower()
            if ('x64' in text_lower or 'neutral' in text_lower) and '.blockmap' not in text_lower:
                if 'whatsappdesktop' in text_lower or 'vclibs' in text_lower or 'ui.xaml' in text_lower or 'windowsappruntime' in text_lower:
                    print(f"Found: {text}")
                    download_list.append({
                        "filename": text,
                        "url": href
                    })
                    
        with open('whatsapp_links.json', 'w', encoding='utf-8') as f:
            json.dump(download_list, f, indent=4)
            
        print(f"Successfully saved {len(download_list)} links to whatsapp_links.json")
        browser.close()

if __name__ == "__main__":
    main()
