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
    sort = sort.replace(sortFunction + '(this.hot.sortOrder)', '(' + cellMeta + '.comparer||' + sortFunction + ')(this.hot.sortOrder)');
    match = sort.match(/^\s*function\s*\(\s*\)\s*\{(.*)\}\s*$/);
    if (!match) {
        throw new Error('Function text not found.');
    }
    plugin.sort = Function(match[1]);
})(Handsontable.plugins.ColumnSorting.prototype);

/******************************************************************************/

Handsontable.CheckboxCell.validator = void 0;
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

Handsontable.TextCell.validator = void 0;
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

Handsontable.NumericCell.validator = void 0;
Handsontable.NumericCell.renderer = function (instance, TD, row, col, prop, value, cellProperties) {
    if (value === null) {
        value = '';
    } else {
        if (typeof value !== 'number') {
            value = Number(value);
        }
        if (cellProperties.language !== void 0 && numeral.language() !== cellProperties.language) {
            numeral.language(cellProperties.language);
        }
        value = numeral(value).format(cellProperties.format || '0');
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
        }
    }
};
