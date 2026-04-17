document.addEventListener('kimai.initialized', function () {
    // ── HELPERS ──────────────────────────────────────────────────────────────

    var programmaticChange = false;

    function realOptions(sel) {
        return Array.from(sel.options).filter(function (o) { return o.value !== ''; });
    }

    function setAndTrigger(sel, value) {
        programmaticChange = true;
        sel.value = value;
        try { $(sel).selectpicker('val', value); } catch (_) {}
        sel.dispatchEvent(new Event('change', { bubbles: true }));
        programmaticChange = false;
    }

    // ── AUTO-SELECT ACTIVITY ──────────────────────────────────────────────────

    function autoSelectActivity(row) {
        var sel = row.querySelector('select[id*="_activity"]');
        if (!sel || sel.value) return;
        var tries = 0;
        var t = setInterval(function () {
            var opts = realOptions(sel);
            if (opts.length > 0 || tries++ > 20) {
                clearInterval(t);
                var dev = opts.filter(function (o) { return o.text.trim().toLowerCase() === 'development'; })[0];
                var pick = dev || (opts.length === 1 ? opts[0] : null);
                if (pick) setAndTrigger(sel, pick.value);
            }
        }, 150);
    }

    // ── AUTO-SELECT PROJECT ───────────────────────────────────────────────────

    function autoSelectProject(row) {
        var sel = row.querySelector('select[id*="_project"]');
        if (!sel) return;
        if (sel.value) { autoSelectActivity(row); return; }
        var opts = realOptions(sel);
        if (opts.length === 1) {
            setAndTrigger(sel, opts[0].value);
            autoSelectActivity(row);
        }
    }

    // ── DELETE BUTTON ─────────────────────────────────────────────────────────

    function addDeleteButton(row) {
        if (row.querySelector('.qe-delete-btn')) return;
        var td = document.createElement('td');
        td.style.cssText = 'vertical-align:middle;padding:4px 6px;';
        td.innerHTML = '<button type="button" class="btn btn-sm btn-danger qe-delete-btn" title="Remove row">'
            + '<i class="fas fa-trash-alt"></i></button>';
        td.querySelector('button').addEventListener('click', function () {
            row.querySelectorAll('input, select').forEach(function (el) {
                el.disabled = true;
                if (el.classList.contains('duration-input')) el.value = '';
            });
            row.style.display = 'none';
            var form = document.getElementById('quick-entries-form');
            if (form) { clearTimeout(saveTimer); form.submit(); }
        });
        row.appendChild(td);
    }

    // Add Delete column header
    var headerRow = document.querySelector('table.dataTable thead tr');
    if (headerRow && !headerRow.querySelector('.qe-delete-th')) {
        var th = document.createElement('th');
        th.className = 'qe-delete-th';
        headerRow.appendChild(th);
    }

    // Add Delete footer cell
    var footerRow = document.querySelector('table.dataTable tfoot tr');
    if (footerRow && !footerRow.querySelector('.qe-delete-tf')) {
        var tff = document.createElement('td');
        tff.className = 'qe-delete-tf';
        footerRow.appendChild(tff);
    }

    // Apply to existing rows
    document.querySelectorAll('.qe-entry-week-row').forEach(function (row) {
        addDeleteButton(row);
        autoSelectProject(row);
    });

    // Watch for newly added rows (via + Add)
    var collection = document.getElementById('ts-collection');
    if (collection) {
        new MutationObserver(function (mutations) {
            mutations.forEach(function (m) {
                m.addedNodes.forEach(function (node) {
                    if (node.nodeType === 1 && node.classList && node.classList.contains('qe-entry-week-row')) {
                        addDeleteButton(node);
                        autoSelectProject(node);
                    }
                });
            });
        }).observe(collection, { childList: true });
    }

    // ── AUTO-SAVE ─────────────────────────────────────────────────────────────

    var saveTimer = null;
    var form = document.getElementById('quick-entries-form');
    if (form) {
        form.addEventListener('change', function (e) {
            if (programmaticChange) return;
            if (!e.target.matches('input.duration-input, select')) return;
            clearTimeout(saveTimer);
            saveTimer = setTimeout(function () { form.submit(); }, 1500);
        });
    }

    // ── SAVE BEFORE WEEK NAVIGATION ───────────────────────────────────────────

    try {
        document.querySelectorAll('form').forEach(function (f) {
            if (f === form) return;
            if (typeof f.submit !== 'function') return;
            var orig = f.submit.bind(f);
            f.submit = function () {
                clearTimeout(saveTimer);
                if (!form) { orig(); return; }
                try {
                    fetch(window.location.href, { method: 'POST', body: new FormData(form) })
                        .catch(function () {}).finally(orig);
                } catch (_) { orig(); }
            };
        });
    } catch (_) {}

});
