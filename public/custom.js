document.addEventListener('kimai.initialized', function (event) {
    const kimai = event.detail.kimai;
    const FORM_SELECT = kimai.getPlugin('form-select');

    // ── HELPERS ──────────────────────────────────────────────────────────────

    function realOptions(selectEl) {
        return Array.from(selectEl.options).filter(o => o.value !== '');
    }

    function setAndTrigger(selectEl, value) {
        selectEl.value = value;
        // Refresh Bootstrap Select if present
        try { $(selectEl).selectpicker('val', value); } catch (e) {}
        selectEl.dispatchEvent(new Event('change', { bubbles: true }));
    }

    // ── AUTO-SELECT ACTIVITY (Development or single option) ──────────────────

    function autoSelectActivity(row) {
        const activitySelect = row.querySelector('select[id*="_activity"]');
        if (!activitySelect) return;

        // Activities load via AJAX after project is chosen — wait for them
        let attempts = 0;
        const interval = setInterval(() => {
            const options = realOptions(activitySelect);
            if (options.length > 0 || attempts++ > 20) {
                clearInterval(interval);
                const dev = options.find(o => o.text.trim().toLowerCase() === 'development');
                const target = dev || (options.length === 1 ? options[0] : null);
                if (target) setAndTrigger(activitySelect, target.value);
            }
        }, 150);
    }

    // ── AUTO-SELECT PROJECT (only when 1 option available) ───────────────────

    function autoSelectProject(row) {
        const projectSelect = row.querySelector('select[id*="_project"]');
        if (!projectSelect) return;
        if (projectSelect.dataset.autoSelectDone) return;

        const options = realOptions(projectSelect);
        if (options.length === 1) {
            projectSelect.dataset.autoSelectDone = '1';
            setAndTrigger(projectSelect, options[0].value);
            autoSelectActivity(row);
        }
    }

    // ── DELETE BUTTON ─────────────────────────────────────────────────────────

    function addDeleteButton(row) {
        if (row.querySelector('.qe-delete-btn')) return;

        const td = document.createElement('td');
        td.style.cssText = 'vertical-align: middle; padding: 4px 6px;';
        td.innerHTML = '<button type="button" class="btn btn-sm btn-danger qe-delete-btn" title="Remove row">'
            + '<i class="ti ti-trash"></i>'
            + '</button>';

        td.querySelector('.qe-delete-btn').addEventListener('click', function () {
            // Disable all inputs so Symfony ignores this row on submit
            row.querySelectorAll('input, select').forEach(el => {
                el.disabled = true;
                if (el.classList.contains('duration-input')) el.value = '';
            });
            row.style.display = 'none';
        });

        row.appendChild(td);
    }

    // Add Delete column header
    const headerRow = document.querySelector('table.dataTable thead tr');
    if (headerRow && !headerRow.querySelector('.qe-delete-th')) {
        const th = document.createElement('th');
        th.className = 'qe-delete-th';
        headerRow.appendChild(th);
    }

    // Add footer cell for alignment
    const footerRow = document.querySelector('table.dataTable tfoot tr');
    if (footerRow && !footerRow.querySelector('.qe-delete-td')) {
        const td = document.createElement('td');
        td.className = 'qe-delete-td';
        footerRow.appendChild(td);
    }

    // Apply to existing rows
    document.querySelectorAll('.qe-entry-week-row').forEach(row => {
        addDeleteButton(row);
        autoSelectProject(row);
    });

    // Watch for newly added rows (via + Add button)
    const collection = document.getElementById('ts-collection');
    if (collection) {
        new MutationObserver(mutations => {
            mutations.forEach(mutation => {
                mutation.addedNodes.forEach(node => {
                    if (node.nodeType === 1 && node.classList && node.classList.contains('qe-entry-week-row')) {
                        addDeleteButton(node);
                        autoSelectProject(node);
                    }
                });
            });
        }).observe(collection, { childList: true });
    }
});
