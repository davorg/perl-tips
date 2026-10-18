(() => {
  "use strict";

  const copyIcon = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true" focusable="false"><rect x="8" y="8" width="12" height="13" rx="2"/><path d="M16 8V5a2 2 0 0 0-2-2H5a2 2 0 0 0-2 2v9a2 2 0 0 0 2 2h3"/></svg>';
  const checkIcon = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true" focusable="false"><path d="m5 12 4 4L19 6"/></svg>';

  document.querySelectorAll("pre").forEach((pre) => {
    const code = pre.querySelector("code");
    if (!code || pre.parentElement.classList.contains("code-block")) return;

    // Keep the button outside the scrolling pre and the copied code.
    const wrapper = document.createElement("div");
    wrapper.className = "code-block";
    pre.before(wrapper);
    wrapper.append(pre);

    const button = document.createElement("button");
    button.type = "button";
    button.className = "code-copy-button";
    button.setAttribute("aria-label", "Copy code");
    button.title = "Copy code";
    button.innerHTML = copyIcon;

    const status = document.createElement("span");
    status.className = "code-copy-status";
    status.setAttribute("role", "status");
    wrapper.append(button, status);

    let resetTimer;
    button.addEventListener("click", async () => {
      clearTimeout(resetTimer);
      button.disabled = true;
      status.textContent = "";
      status.removeAttribute("data-error");
      button.removeAttribute("data-copied");
      button.innerHTML = copyIcon;

      try {
        // textContent preserves indentation and newlines without Rouge's HTML.
        await navigator.clipboard.writeText(code.textContent);
        button.innerHTML = checkIcon;
        button.setAttribute("data-copied", "");
        button.setAttribute("aria-label", "Code copied");
        button.title = "Copied!";
        status.textContent = "Copied!";
      } catch {
        // Clipboard access can be unavailable or denied. Select exactly the
        // code and give an honest, visible fallback instead of claiming success.
        const selection = window.getSelection();
        if (selection) {
          const range = document.createRange();
          range.selectNodeContents(code);
          selection.removeAllRanges();
          selection.addRange(range);
        }
        button.setAttribute("aria-label", "Copy code");
        button.title = "Copy code";
        status.setAttribute("data-error", "");
        status.textContent = "Couldn't copy automatically. Select the code and use your device's copy command.";
      } finally {
        button.disabled = false;
      }

      if (button.hasAttribute("data-copied")) {
        resetTimer = setTimeout(() => {
          button.innerHTML = copyIcon;
          button.removeAttribute("data-copied");
          button.setAttribute("aria-label", "Copy code");
          button.title = "Copy code";
          status.textContent = "";
        }, 2500);
      }
    });
  });
})();
