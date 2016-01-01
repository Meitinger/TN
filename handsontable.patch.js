Handsontable.DefaultSettings.comparer = void 0;
(function (plugin) {
    var match;
    var sort = plugin.sort.toString();
    match = sort.match(/(\w+)\s*=\s*this\.hot\.getCellMeta/);
    if (!match) {
        throw new Error('Cell properties variable not found.');
    }
    var cellMeta = match[1];
    match = sort.match(/(\w+)\s*=\s*this\.defaultSort/);
    if (!match) {
        throw new Error('Sort function variable not found.');
    }
    var sortFunction = match[1];
    sort = sort.replace(sortFunction + '(this.hot.sortOrder)', '(typeof ' + cellMeta + '.comparer === "function" ? ' + cellMeta + '.comparer(this.hot.sortOrder) : ' + sortFunction + '(this.hot.sortOrder))');
    match = sort.match(/^\s*function\s*\(\s*\)\s*\{(.*)\}\s*$/);
    if (!match) {
        throw new Error('Function text not found.');
    }
    plugin.sort = Function(match[1]);
})(Handsontable.plugins.ColumnSorting.prototype);

/******************************************************************************/

Handsontable.DefaultSettings.formatCopyable = void 0;
var origGetCopyable = Handsontable.DataMap.prototype.getCopyable;
Handsontable.DataMap.prototype.getCopyable = function (row, prop) {
    var result = origGetCopyable.call(this, row, prop);
    if (result === '' || result === null) {
        return '';
    }
    var col = this.propToCol(prop);
    var meta = this.instance.getCellMeta(row, col);
    return meta.formatCopyable ? meta.formatCopyable(result, row, col, prop) : result;
};

/******************************************************************************/

Handsontable.CheckboxCell.formatCopyable = function (value) {
    return value ? '1' : '0';
};
Handsontable.CheckboxCell.comparer = function (sortOrder) {
    if (sortOrder) {
        return function (a, b) {
            return (b[1] === null ? -1 : b[1]) - (a[1] === null ? -1 : a[1]);
        };
    } else {
        return function (a, b) {
            return (a[1] === null ? -1 : a[1]) - (b[1] === null ? -1 : b[1]);
        };
    }
};

/******************************************************************************/

Handsontable.editors.TextEditor.prototype.getValue = function () {
    return this.TEXTAREA.value === '' ? null : this.TEXTAREA.value;
};
Handsontable.TextCell.formatCopyable = function (value) {
    return '"' + value.replace(/"/g, '""') + '"';
};
Handsontable.TextCell.comparer = function (sortOrder) {
    if (window.Intl && window.Intl.Collator) {
        var collator = new Intl.Collator(this.language);
        if (sortOrder) {
            return function (a, b) { return collator.compare(a[1], b[1]); };
        } else {
            return function (a, b) { return collator.compare(b[1], a[1]); };
        }
    } else {
        return Handsontable.plugins.ColumnSorting.prototype.defaultSort(sortOrder);
    }
};

/******************************************************************************/

Handsontable.editors.NumericEditor.prototype.getValue = function () {
    if (this.TEXTAREA.value === '') {
        return null;
    }
    return this.TEXTAREA.value;

    // try to convert to number or return string
};
// validator: return true if number or null
// allowInvalid: false
Handsontable.NumericCell.formatCopyable = function (value) {
    return value.toLocaleString();
};
Handsontable.NumericCell.renderer = function (instance, TD, row, col, prop, value, cellProperties) {
    if (value === null) {
        value = '';
    } else {
        var format = true;
        if (typeof value !== 'number') {
            var converted = Number(value);
            if (isNaN(converted)) {
                format = false;
            }
            else {
                value = converted;
            }
        }
        else if (isNaN(value)) {
            value = 'NaN';
            format = false;
        }
        if (format) {
            if (cellProperties.language !== void 0 && numeral.language() !== cellProperties.language) {
                numeral.language(cellProperties.language);
            }
            value = numeral(value).format(cellProperties.format || '0');
        }
    }
    Handsontable.renderers.TextRenderer(instance, TD, row, col, prop, value, cellProperties);
};
Handsontable.NumericCell.comparer = function (sortOrder) {
    if (sortOrder) {
        return function (a, b) {
            if (a[1] === null || b[1] === null) {
                return (b[1] === null) - (a[1] === null);
            } else if (isNaN(a[1]) || isNaN(b[1])) {
                return isNaN(b[1]) - isNaN(a[1]);
            } else {
                return a[1] < b[1] ? -1 : b[1] < a[1] ? 1 : 0;
            }
        };
    } else {
        return function (a, b) {
            if (a[1] === null || b[1] === null) {
                return (a[1] === null) - (b[1] === null);
            } else if (isNaN(a[1]) || isNaN(b[1])) {
                return isNaN(a[1]) - isNaN(b[1]);
            } else {
                return a[1] < b[1] ? 1 : b[1] < a[1] ? -1 : 0;
            }
        };
    }
};
Handsontable.NumericCell.className = 'htNumeric';

/******************************************************************************/

Handsontable.DateCell.validator = void 0;
Handsontable.DateCell.formatCopyable = function (value) {
    return value.toLocaleDateString();
};
Handsontable.DateCell.renderer = function (instance, TD, row, col, prop, value, cellProperties) {
    if (value === null) {
        value = '';
    } else {
        if (!(value instanceof Date)) {
            value = Date(value);
        }
        value = moment(value).format(cellProperties.dateFormat || Handsontable.editors.getEditor('date', instance).defaultDateFormat);
    }
    Handsontable.renderers.AutocompleteRenderer(instance, TD, row, col, prop, value, cellProperties);
};
Handsontable.DateCell.comparer = function (sortOrder) {
    if (sortOrder) {
        return function (a, b) {
            return a[1] !== null && b[1] !== null ? (a[1] < b[1] ? -1 : b[1] < a[1] ? 1 : 0) : a[1] !== null ? 1 : b[1] !== null ? -1 : 0;
        };
    } else {
        return function (a, b) {
            return a[1] !== null && b[1] !== null ? (a[1] < b[1] ? 1 : b[1] < a[1] ? -1 : 0) : a[1] !== null ? -1 : b[1] !== null ? 1 : 0;
        };
    }
};
