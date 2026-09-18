let tagMeasurementsMap = {};
let alertTimeout = null;

const INPUT_UNITS = [
  { value: 'm',   label: 'm' },
  { value: 'm2',  label: 'm²' },
  { value: 'm3',  label: 'm³' },
  { value: 'pcs', label: 'pcs' } // <-- เพิ่ม pcs ตรงนี้
];

// Helper: ถ้านิ่งหรือเป็น 0 ให้ส่งค่าว่าง "" กลับไป
function formatNum(num) {
  if (num === null || num === undefined || num === '') return '';
  const parsed = parseFloat(num);
  if (isNaN(parsed) || parsed === 0) return '';
  return parsed.toFixed(2);
}

// Custom UI Alert/Toast
function showAlert(message, duration = 3000) {
  const toast = document.getElementById('toastNotification');
  const toastMsg = document.getElementById('toastMessage');
  
  if (!toast || !toastMsg) return;

  toastMsg.textContent = message;
  toast.classList.remove('hidden');

  if (alertTimeout) clearTimeout(alertTimeout);

  alertTimeout = setTimeout(() => {
    hideAlert();
  }, duration);
}

function hideAlert() {
  const toast = document.getElementById('toastNotification');
  if (toast) {
    toast.classList.add('hidden');
  }
}

function callSketchup(method, ...args) {
  const bridge = window.sketchup;
  if (bridge && typeof bridge[method] === 'function') {
    bridge[method](...args);
  } else {
    console.warn(`Sketchup bridge method "${method}" is not available.`);
  }
}

function populateTags(tags) {
  const select = document.getElementById('tagSelect');
  if (!select) return;
  select.innerHTML = '';

  if (!tags || tags.length === 0) {
    select.innerHTML = '<option value="">-- No Tags in Model --</option>';
    return;
  }

  const defaultOption = document.createElement('option');
  defaultOption.value = '';
  defaultOption.textContent = '';
  select.appendChild(defaultOption);

  tags.forEach((tag) => {
    const option = document.createElement('option');
    option.value = tag;
    option.textContent = tag;
    select.appendChild(option);
  });
}

function updateTagMeasurements(tagName, measurements) {
  tagMeasurementsMap[tagName] = measurements || {};
  refreshAllRowQuantities();
}

function refreshAllRowQuantities() {
  document.querySelectorAll('#tableBody tr').forEach((tr) => {
    const tagName = tr.getAttribute('data-tag-name');
    const unitSelect = tr.querySelector('.unit-select');
    const qtyInput = tr.querySelector('.qty-input');

    if (tagName && unitSelect && qtyInput && tagMeasurementsMap[tagName]) {
      const selectedUnit = unitSelect.value;
      
      // ถ้ายูนิตไม่ใช่ pcs ให้ดึงค่าจาก SketchUp
      if (selectedUnit !== 'pcs') {
        const measurements = tagMeasurementsMap[tagName];
        const rawQty = measurements[selectedUnit] ?? measurements['m2'] ?? 0;
        qtyInput.value = formatNum(rawQty);
        calculateRowCalculations(tr);
      }
    }
  });
  updateGrandTotals();
}

function calculateRowCalculations(tr) {
  const qty = parseFloat(tr.querySelector('.qty-input').value) || 0;
  const factorVal = tr.querySelector('.factor-input').value;
  const factor = factorVal !== '' ? parseFloat(factorVal) : 1.0;
  
  const weightPerUnit = parseFloat(tr.querySelector('.weight-unit-input').value) || 0;
  const unitCost = parseFloat(tr.querySelector('.cost-input').value) || 0;
  const wastePercent = parseFloat(tr.querySelector('.waste-input').value) || 0;
  const taxPercent = parseFloat(tr.querySelector('.tax-input').value) || 0;

  const rowWeightTotal = qty * factor * weightPerUnit;
  const rowWeightInput = tr.querySelector('.row-weight-input');
  if (rowWeightInput) {
    rowWeightInput.value = rowWeightTotal > 0 ? rowWeightTotal.toLocaleString('en-US', {
      minimumFractionDigits: 2,
      maximumFractionDigits: 2
    }) : '';
    rowWeightInput.setAttribute('data-raw-weight', rowWeightTotal);
  }

  const baseCost = qty * factor * unitCost;
  const withWaste = baseCost * (1 + wastePercent / 100);
  const totalCost = withWaste * (1 + taxPercent / 100);

  const totalCostInput = tr.querySelector('.total-cost-input');
  if (totalCostInput) {
    totalCostInput.value = totalCost > 0 ? totalCost.toLocaleString('en-US', {
      minimumFractionDigits: 2,
      maximumFractionDigits: 2
    }) : '';
    totalCostInput.setAttribute('data-raw-value', totalCost);
  }

  updateGrandTotals();
}

function updateGrandTotals() {
  const grandTotalCostInput = document.getElementById('grandTotalCost');
  const grandTotalWeightInput = document.getElementById('grandTotalWeight');

  let grandTotalCost = 0;
  let grandTotalWeight = 0;

  document.querySelectorAll('#tableBody tr').forEach((tr) => {
    const totalCostInput = tr.querySelector('.total-cost-input');
    const rowWeightInput = tr.querySelector('.row-weight-input');

    if (totalCostInput) {
      grandTotalCost += parseFloat(totalCostInput.getAttribute('data-raw-value')) || 0;
    }
    if (rowWeightInput) {
      grandTotalWeight += parseFloat(rowWeightInput.getAttribute('data-raw-weight')) || 0;
    }
  });

  if (grandTotalCostInput) {
    grandTotalCostInput.value = grandTotalCost > 0 ? grandTotalCost.toLocaleString('en-US', {
      minimumFractionDigits: 2,
      maximumFractionDigits: 2
    }) : '0.00';
  }

  if (grandTotalWeightInput) {
    grandTotalWeightInput.value = grandTotalWeight > 0 ? grandTotalWeight.toLocaleString('en-US', {
      minimumFractionDigits: 2,
      maximumFractionDigits: 2
    }) : '0.00';
  }
}

function createRow(data = {}) {
  const tr = document.createElement('tr');
  const tagSelect = document.getElementById('tagSelect');

  const tagName = data.tag || (tagSelect ? tagSelect.value : '') || '';
  tr.setAttribute('data-tag-name', tagName);

  if (tagName) {
    callSketchup('get_tag_measurements', tagName);
  }

  const measurements = tagMeasurementsMap[tagName] || {};
  const currentUnit = data.input || 'm2';
  
  // กำหนดค่าเริ่มต้นของ Quantity
  let rawQty;
  if (currentUnit === 'pcs') {
    rawQty = data.quantity ?? 1; // ถ้าเป็น pcs ให้ใช้ค่าจาก data หรือเริ่มต้นที่ 1
  } else {
    rawQty = measurements[currentUnit] ?? data.quantity;
  }
  const initialQty = formatNum(rawQty);

  const unitOptionsHtml = INPUT_UNITS.map(u => 
    `<option value="${u.value}" ${u.value === currentUnit ? 'selected' : ''}>${u.label}</option>`
  ).join('');

  tr.innerHTML = `
    <td>
      <div class="drag-handle" title="Drag to reorder">
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="9" cy="5" r="1.5"></circle><circle cx="9" cy="12" r="1.5"></circle><circle cx="9" cy="19" r="1.5"></circle><circle cx="15" cy="5" r="1.5"></circle><circle cx="15" cy="12" r="1.5"></circle><circle cx="15" cy="19" r="1.5"></circle></svg>
      </div>
    </td>
    <td><input type="text" class="input-control tag-input" value="${tagName}" readonly tabindex="-1" style="background-color: #f8fafc; color: #334155; font-weight: 600; cursor: not-allowed;" /></td>
    <td><input type="text" class="input-control desc-input" value="${data.description || tagName}"></td>
    <td><input type="number" step="any" class="input-control text-right qty-input" value="${initialQty}" /></td>
    <td>
      <select class="input-control unit-select text-center" style="font-weight: 600; color: #334155;">
        ${unitOptionsHtml}
      </select>
    </td>
    <td><input type="number" step="0.1" class="input-control text-right factor-input" value="${formatNum(data.factor ?? 1.0)}"></td>
    <td><input type="number" step="0.01" class="input-control text-right weight-unit-input" value="${formatNum(data.weightUnit)}"></td>
    <td><input type="text" class="input-control text-right row-weight-input" value="" readonly tabindex="-1" style="background-color: #f1f5f9; color: #334155; font-weight: 600; cursor: not-allowed;" /></td>
    <td><input type="number" step="0.01" class="input-control text-right cost-input" value="${formatNum(data.unitCost)}"></td>
    <td><input type="number" step="0.1" class="input-control text-right waste-input" value="${formatNum(data.waste)}"></td>
    <td><input type="number" step="0.1" class="input-control text-right tax-input" value="${formatNum(data.tax)}"></td>
    <td><input type="text" class="input-control text-right total-cost-input" value="" readonly tabindex="-1" style="background-color: #f1f5f9; color: #0f172a; font-weight: 700; cursor: not-allowed;" /></td>
    <td>
      <button type="button" class="action-btn comment-btn" title="Comment">
        <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"></path></svg>
      </button>
    </td>
    <td>
      <button type="button" class="action-btn delete-btn" title="Delete">
        <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="3 6 5 6 21 6"></polyline><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"></path></svg>
      </button>
    </td>
  `;

  const unitSelect = tr.querySelector('.unit-select');
  const qtyInput = tr.querySelector('.qty-input');

  // ฟังก์ชันควบคุมการพิมพ์ Quantity ตามประเภทยูนิต
  const toggleQtyState = (unit) => {
    if (unit === 'pcs') {
      qtyInput.removeAttribute('readonly');
      qtyInput.removeAttribute('tabindex');
      qtyInput.style.backgroundColor = '#ffffff';
      qtyInput.style.cursor = 'text';
    } else {
      qtyInput.setAttribute('readonly', 'true');
      qtyInput.setAttribute('tabindex', '-1');
      qtyInput.style.backgroundColor = '#f1f5f9';
      qtyInput.style.cursor = 'not-allowed';
    }
  };

  // เรียกใช้ตั้งค่าครั้งแรก
  toggleQtyState(currentUnit);

  unitSelect.addEventListener('change', (e) => {
    const selectedUnit = e.target.value;
    toggleQtyState(selectedUnit);

    if (selectedUnit !== 'pcs') {
      const measurements = tagMeasurementsMap[tagName] || {};
      qtyInput.value = formatNum(measurements[selectedUnit]);
    }
    calculateRowCalculations(tr);
  });

  // ฟัง Event เพิ่มเติมเมื่อมีการแก้ตัวเลข Manual ใน qtyInput
  qtyInput.addEventListener('input', () => calculateRowCalculations(tr));

  ['.factor-input', '.weight-unit-input', '.cost-input', '.waste-input', '.tax-input'].forEach(selector => {
    tr.querySelector(selector).addEventListener('input', () => calculateRowCalculations(tr));
  });

  calculateRowCalculations(tr);

  tr.querySelector('.delete-btn').addEventListener('click', () => {
    tr.remove();
    updateGrandTotals();
  });

  // --- Drag and Drop Logic ---
  const dragHandle = tr.querySelector('.drag-handle');
  dragHandle.addEventListener('mousedown', () => tr.setAttribute('draggable', 'true'));
  dragHandle.addEventListener('mouseup', () => tr.removeAttribute('draggable'));
  dragHandle.addEventListener('mouseleave', () => tr.removeAttribute('draggable'));

  tr.addEventListener('dragstart', (e) => {
    e.dataTransfer.effectAllowed = 'move';
    setTimeout(() => tr.classList.add('dragging'), 0);
  });

  tr.addEventListener('dragend', () => {
    tr.classList.remove('dragging');
    tr.removeAttribute('draggable');
    document.querySelectorAll('#tableBody tr').forEach(row => {
      row.style.borderTop = "";
      row.style.borderBottom = "";
    });
  });

  tr.addEventListener('dragover', (e) => {
    e.preventDefault();
    const draggingRow = document.querySelector('.dragging');
    if (!draggingRow || draggingRow === tr) return;

    const bounding = tr.getBoundingClientRect();
    const offset = e.clientY - bounding.top;
    if (offset > bounding.height / 2) {
      tr.style.borderBottom = "2px solid #2563eb";
      tr.style.borderTop = "";
    } else {
      tr.style.borderTop = "2px solid #2563eb";
      tr.style.borderBottom = "";
    }
  });

  tr.addEventListener('dragleave', () => {
    tr.style.borderTop = "";
    tr.style.borderBottom = "";
  });

  tr.addEventListener('drop', (e) => {
    e.preventDefault();
    tr.style.borderTop = "";
    tr.style.borderBottom = "";
    const draggingRow = document.querySelector('.dragging');
    if (!draggingRow || draggingRow === tr) return;

    const bounding = tr.getBoundingClientRect();
    const offset = e.clientY - bounding.top;
    const tbody = tr.parentNode;

    if (offset > bounding.height / 2) {
      tbody.insertBefore(draggingRow, tr.nextSibling);
    } else {
      tbody.insertBefore(draggingRow, tr);
    }
  });

  return tr;
}

function applyImportedCsvData(items) {
  if (!items || items.length === 0) return;
  const tableBody = document.getElementById('tableBody');
  if (!tableBody) return;

  tableBody.innerHTML = '';
  items.forEach(item => tableBody.appendChild(createRow(item)));
  updateGrandTotals();
}

function loadAllSavedRows(savedData) {
  const tableBody = document.getElementById('tableBody');
  if (!tableBody) return;
  tableBody.innerHTML = '';

  if (savedData && savedData.items && savedData.items.length > 0) {
    savedData.items.forEach(item => tableBody.appendChild(createRow(item)));
  }
  updateGrandTotals();
}

function getFormData() {
  const rowsData = [];
  document.querySelectorAll('#tableBody tr').forEach((tr) => {
    const totalCostInput = tr.querySelector('.total-cost-input');
    const rowWeightInput = tr.querySelector('.row-weight-input');

    const factorVal = tr.querySelector('.factor-input').value;

    rowsData.push({
      tag: tr.getAttribute('data-tag-name') || tr.querySelector('.tag-input').value || '',
      description: tr.querySelector('.desc-input').value,
      input: tr.querySelector('.unit-select').value,
      quantity: parseFloat(tr.querySelector('.qty-input').value) || 0,
      factor: factorVal !== '' ? parseFloat(factorVal) : 1.0,
      weightUnit: parseFloat(tr.querySelector('.weight-unit-input').value) || 0,
      weightTotal: parseFloat(rowWeightInput ? rowWeightInput.getAttribute('data-raw-weight') : 0) || 0,
      unitCost: parseFloat(tr.querySelector('.cost-input').value) || 0,
      waste: parseFloat(tr.querySelector('.waste-input').value) || 0,
      tax: parseFloat(tr.querySelector('.tax-input').value) || 0,
      cost: parseFloat(totalCostInput ? totalCostInput.getAttribute('data-raw-value') : 0) || 0
    });
  });

  return { items: rowsData };
}

// ==========================================
// Column Resizing & Persistence Logic
// ==========================================
function initColumnResizing() {
  const table = document.getElementById('mainTable');
  if (!table) return;

  const cols = table.querySelectorAll('th');
  const savedWidths = JSON.parse(localStorage.getItem('materialCost_colWidths') || '{}');

  cols.forEach(col => {
    const colId = col.getAttribute('data-col-id');
    
    // โหลดค่าความกว้างที่บันทึกไว้
    if (colId && savedWidths[colId]) {
      col.style.width = savedWidths[colId] + 'px';
    }

    const resizer = col.querySelector('.resizer');
    if (!resizer) return;

    let startX = 0;
    let startWidth = 0;

    const onMouseDown = (e) => {
      e.stopPropagation(); // ไม่ให้ไป trigger การ sort คอลัมน์
      startX = e.clientX;
      startWidth = col.offsetWidth;

      resizer.classList.add('resizing');

      document.addEventListener('mousemove', onMouseMove);
      document.addEventListener('mouseup', onMouseUp);
    };

    const onMouseMove = (e) => {
      const width = startWidth + (e.clientX - startX);
      if (width > 30) { // ขั้นต่ำ 30px
        col.style.width = width + 'px';
      }
    };

    const onMouseUp = () => {
      resizer.classList.remove('resizing');
      document.removeEventListener('mousemove', onMouseMove);
      document.removeEventListener('mouseup', onMouseUp);

      // บันทึกค่าลง localStorage
      if (colId) {
        const currentWidths = JSON.parse(localStorage.getItem('materialCost_colWidths') || '{}');
        currentWidths[colId] = col.offsetWidth;
        localStorage.setItem('materialCost_colWidths', JSON.stringify(currentWidths));
      }
    };

    resizer.addEventListener('mousedown', onMouseDown);
  });
}

document.addEventListener('DOMContentLoaded', () => {
  initColumnResizing();

  const tagSelect = document.getElementById('tagSelect');
  const tableBody = document.getElementById('tableBody');
  const addRowBtn = document.getElementById('addRowBtn');

  if (addRowBtn) {
    addRowBtn.addEventListener('click', () => {
      const selectedTag = tagSelect ? tagSelect.value : '';
      if (!selectedTag) {
        showAlert('Please select a tag before adding a row.');
        return;
      }
      tableBody.appendChild(createRow({ tag: selectedTag, description: selectedTag }));
      updateGrandTotals();
    });
  }

  const saveBtn = document.getElementById('saveBtn');
  if (saveBtn) {
    saveBtn.addEventListener('click', () => {
      callSketchup('save_tag_cost_data', getFormData());
      showAlert('Data saved successfully.');
    });
  }

  const csvBtn = document.getElementById('csvBtn');
  if (csvBtn) {
    csvBtn.addEventListener('click', () => {
      callSketchup('export_csv_data', getFormData());
    });
  }

  const importCsvBtn = document.getElementById('importCsvBtn');
  if (importCsvBtn) {
    importCsvBtn.addEventListener('click', () => {
      callSketchup('import_csv_data');
    });
  }

  // --- Sorting Logic ---
  document.querySelectorAll('.sortable').forEach(th => {
    th.addEventListener('click', (e) => {
      // ถ้าคลิกโดน resizer ไม่ต้อง sort
      if (e.target.classList.contains('resizer')) return;

      const type = th.getAttribute('data-sort-type');
      const selector = th.getAttribute('data-sort-selector');
      const currentOrder = th.getAttribute('data-order');
      const newOrder = currentOrder === 'asc' ? 'desc' : 'asc';

      document.querySelectorAll('.sortable').forEach(el => el.removeAttribute('data-order'));
      th.setAttribute('data-order', newOrder);

      const tbody = document.getElementById('tableBody');
      const rows = Array.from(tbody.querySelectorAll('tr'));

      rows.sort((a, b) => {
        let valA, valB;
        const elA = a.querySelector(selector);
        const elB = b.querySelector(selector);

        if (type === 'number') {
          valA = parseFloat(elA.getAttribute('data-raw-value') || elA.getAttribute('data-raw-weight') || elA.value.replace(/,/g, '')) || 0;
          valB = parseFloat(elB.getAttribute('data-raw-value') || elB.getAttribute('data-raw-weight') || elB.value.replace(/,/g, '')) || 0;
        } else {
          valA = (elA.value || '').toLowerCase();
          valB = (elB.value || '').toLowerCase();
        }

        if (valA < valB) return newOrder === 'asc' ? -1 : 1;
        if (valA > valB) return newOrder === 'asc' ? 1 : -1;
        return 0;
      });

      tbody.innerHTML = '';
      rows.forEach(row => tbody.appendChild(row));
    });
  });

  callSketchup('get_tags');
  callSketchup('get_all_saved_data');
});