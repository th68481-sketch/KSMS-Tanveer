import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';

typedef CellBuilder = Widget Function(BuildContext context, Map<String, dynamic> row);

class KsmsColumn {
  KsmsColumn({
    required this.key,
    required this.label,
    this.builder,
    this.numeric = false,
    this.size = ColumnSize.S,
    this.comparator,
  });

  final String key;
  final String label;
  final CellBuilder? builder;
  final bool numeric;
  final ColumnSize size;
  final int Function(Map<String, dynamic> a, Map<String, dynamic> b)? comparator;
}

/// Searchable, sortable, paginated table for desktop/web with a card-list
/// fallback for narrow layouts.
class KsmsTable extends StatefulWidget {
  const KsmsTable({
    super.key,
    required this.columns,
    required this.rows,
    this.onRowTap,
    this.searchHint,
    this.trailing,
    this.emptyBuilder,
    this.pageSize = 15,
    this.searchableKeys,
  });

  final List<KsmsColumn> columns;
  final List<Map<String, dynamic>> rows;
  final void Function(Map<String, dynamic> row)? onRowTap;
  final String? searchHint;
  final Widget? trailing;
  final Widget? emptyBuilder;
  final int pageSize;
  final List<String>? searchableKeys;

  @override
  State<KsmsTable> createState() => _KsmsTableState();
}

class _KsmsTableState extends State<KsmsTable> {
  int _sortColumn = -1;
  bool _ascending = true;
  int _page = 0;
  String _query = '';

  List<Map<String, dynamic>> get _filtered {
    var rows = widget.rows;
    if (_query.isNotEmpty) {
      final keys = widget.searchableKeys ?? widget.columns.map((c) => c.key).toList();
      final q = _query.toLowerCase();
      rows = rows.where((r) => keys.any((k) =>
          (r[k] ?? '')?.toString().toLowerCase().contains(q) == true)).toList();
    }
    if (_sortColumn >= 0 && _sortColumn < widget.columns.length) {
      final col = widget.columns[_sortColumn];
      int cmp(Map<String, dynamic> a, Map<String, dynamic> b) {
        if (col.comparator != null) return col.comparator!(a, b);
        final av = a[col.key];
        final bv = b[col.key];
        if (av is num && bv is num) return av.compareTo(bv);
        return (av ?? '').toString().compareTo((bv ?? '').toString());
      }

      rows = [...rows]..sort((a, b) => _ascending ? cmp(a, b) : cmp(b, a));
    }
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final rows = _filtered;
    final pages = (rows.length / widget.pageSize).ceil().clamp(1, 1 << 30);
    if (_page >= pages) _page = pages - 1;
    final pageRows =
        rows.skip(_page * widget.pageSize).take(widget.pageSize).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                onChanged: (v) {
                  setState(() {
                    _query = v;
                    _page = 0;
                  });
                },
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search, size: 20),
                  hintText: widget.searchHint ?? 'Search…',
                  isDense: true,
                ),
              ),
            ),
            if (widget.trailing != null) ...[
              const SizedBox(width: KsmsSpacing.sm),
              widget.trailing!,
            ],
          ],
        ),
        const SizedBox(height: KsmsSpacing.sm),
        Expanded(
          child: rows.isEmpty
              ? (widget.emptyBuilder ?? const SizedBox.shrink())
              : LayoutBuilder(builder: (context, c) {
                  if (c.maxWidth < 640) {
                    return _cardList(pageRows, rows.length, pages);
                  }
                  return DataTable2(
                    columnSpacing: 12,
                    horizontalMargin: 8,
                    minWidth: 600,
                    sortColumnIndex: _sortColumn < 0 ? null : _sortColumn,
                    sortAscending: _ascending,
                    columns: [
                      for (var i = 0; i < widget.columns.length; i++)
                        DataColumn2(
                          label: Text(widget.columns[i].label,
                              style: Theme.of(context).textTheme.labelLarge),
                          numeric: widget.columns[i].numeric,
                          size: widget.columns[i].size,
                          onSort: (_, __) => setState(() {
                            if (_sortColumn == i) {
                              _ascending = !_ascending;
                            } else {
                              _sortColumn = i;
                              _ascending = true;
                            }
                          }),
                        ),
                    ],
                    rows: [
                      for (final r in pageRows)
                        DataRow2(
                          onTap: widget.onRowTap == null ? null : () => widget.onRowTap!(r),
                          cells: [
                            for (final col in widget.columns)
                              DataCell(col.builder?.call(context, r) ??
                                  Text((r[col.key] ?? '—')?.toString() ?? '—',
                                      overflow: TextOverflow.ellipsis)),
                          ],
                        ),
                    ],
                  );
                }),
        ),
        if (rows.length > widget.pageSize)
          Padding(
            padding: const EdgeInsets.only(top: KsmsSpacing.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('${_page + 1} / $pages',
                    style: Theme.of(context).textTheme.labelMedium),
                IconButton(
                  onPressed: _page > 0 ? () => setState(() => _page--) : null,
                  icon: const Icon(Icons.chevron_left),
                ),
                IconButton(
                  onPressed: _page < pages - 1 ? () => setState(() => _page++) : null,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _cardList(List<Map<String, dynamic>> pageRows, int total, int pages) {
    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            itemCount: pageRows.length,
            separatorBuilder: (_, __) => const SizedBox(height: KsmsSpacing.xs),
            itemBuilder: (context, i) {
              final r = pageRows[i];
              return Card(
                child: InkWell(
                  borderRadius: KsmsRadii.md,
                  onTap: widget.onRowTap == null ? null : () => widget.onRowTap!(r),
                  child: Padding(
                    padding: const EdgeInsets.all(KsmsSpacing.card),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final col in widget.columns.take(5))
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 110,
                                  child: Text(col.label,
                                      style: Theme.of(context).textTheme.labelSmall),
                                ),
                                Expanded(
                                  child: col.builder?.call(context, r) ??
                                      Text((r[col.key] ?? '—')?.toString() ?? '—',
                                          style: Theme.of(context).textTheme.bodyMedium),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (total > widget.pageSize)
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('${_page + 1} / $pages', style: Theme.of(context).textTheme.labelMedium),
              IconButton(
                onPressed: _page > 0 ? () => setState(() => _page--) : null,
                icon: const Icon(Icons.chevron_left),
              ),
              IconButton(
                onPressed: _page < pages - 1 ? () => setState(() => _page++) : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
      ],
    );
  }
}
