document.addEventListener("DOMContentLoaded", () => {
    document.querySelectorAll("[data-copy-target]").forEach(button => {
        button.addEventListener("click", async () => {
            const selector = button.getAttribute("data-copy-target");
            const target = document.querySelector(selector);
            if (!target) return;

            try {
                await navigator.clipboard.writeText(target.innerText.trim());
                const original = button.innerHTML;
                button.innerHTML = '<i class="bi bi-check2 me-1"></i>Copied';
                setTimeout(() => button.innerHTML = original, 1400);
            } catch (e) {
                console.warn("Clipboard copy failed", e);
            }
        });
    });
});
