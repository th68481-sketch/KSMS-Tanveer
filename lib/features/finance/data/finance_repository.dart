import 'package:supabase_flutter/supabase_flutter.dart';

class FinanceRepository {
  FinanceRepository(this._client);
  final SupabaseClient _client;

  // --- Fee Heads / Plans / Discounts ---
  Future<List<Map<String, dynamic>>> listFeeHeads(String tenantId) async {
    final rows = await _client.from('fee_heads').select('*').eq('tenant_id', tenantId);
    return rows.cast<Map<String, dynamic>>();
  }

  // --- Invoices ---
  Future<List<Map<String, dynamic>>> listInvoices(String tenantId) async {
    final rows = await _client.from('invoices').select('*').eq('tenant_id', tenantId).order('issue_date', ascending: false);
    return rows.cast<Map<String, dynamic>>();
  }

  // --- Payments / Receipts ---
  Future<void> recordPayment(Map<String, dynamic> paymentData) async {
    await _client.from('payments').insert(paymentData);
  }

  // --- Grants / Budgets / Expenses ---
  Future<List<Map<String, dynamic>>> listExpenses(String tenantId) async {
    final rows = await _client.from('expenses').select('*').eq('tenant_id', tenantId);
    return rows.cast<Map<String, dynamic>>();
  }

  // --- Immutable Ledger Logic ---
  Future<void> postLedgerEntry(Map<String, dynamic> entry) async {
    await _client.schema('app').rpc('post_ledger_entry', params: entry);
  }
}
