// Flutter Currency Rates Example
// This file demonstrates how to fetch and use currency conversion rates

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// ============================================================================
// MODEL CLASSES
// ============================================================================

class Currency {
  final int id;
  final String name;
  final String symbol;
  final String code;
  final double conversionRate;

  Currency({
    required this.id,
    required this.name,
    required this.symbol,
    required this.code,
    required this.conversionRate,
  });

  factory Currency.fromJson(Map<String, dynamic> json) {
    return Currency(
      id: json['id'],
      name: json['name'],
      symbol: json['symbol'],
      code: json['code'],
      conversionRate: (json['conversion_rate'] as num).toDouble(),
    );
  }

  // Helper method to format currency with symbol
  String formatAmount(double amount) {
    return '$symbol${amount.toStringAsFixed(2)}';
  }
}

class CurrencyRatesResponse {
  final List<Currency> currencies;
  final int count;
  final String lastUpdated;

  CurrencyRatesResponse({
    required this.currencies,
    required this.count,
    required this.lastUpdated,
  });

  factory CurrencyRatesResponse.fromJson(Map<String, dynamic> json) {
    var data = json['data'];
    return CurrencyRatesResponse(
      currencies: (data['currencies'] as List)
          .map((currency) => Currency.fromJson(currency))
          .toList(),
      count: data['count'],
      lastUpdated: data['last_updated'],
    );
  }
}

// ============================================================================
// API SERVICE
// ============================================================================

class CurrencyRatesService {
  static const String baseUrl = 'https://ruyadream.com/velox/api';

  /// Fetch all currency rates
  static Future<CurrencyRatesResponse> getCurrencyRates({String? search}) async {
    var uri = Uri.parse('$baseUrl/currency_rates.php');
    
    if (search != null && search.isNotEmpty) {
      uri = uri.replace(queryParameters: {'search': search});
    }

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      if (jsonData['success']) {
        return CurrencyRatesResponse.fromJson(jsonData);
      } else {
        throw Exception(jsonData['message']);
      }
    } else {
      throw Exception('Failed to load currency rates');
    }
  }

  /// Convert amount from one currency to another
  static double convertCurrency(
    double amount,
    Currency fromCurrency,
    Currency toCurrency,
  ) {
    // Convert to base currency (USD) first, then to target currency
    double amountInBase = amount / fromCurrency.conversionRate;
    return amountInBase * toCurrency.conversionRate;
  }
}

// ============================================================================
// CURRENCY SELECTOR WIDGET
// ============================================================================

class CurrencySelector extends StatefulWidget {
  final Currency? selectedCurrency;
  final Function(Currency) onCurrencySelected;

  const CurrencySelector({
    Key? key,
    this.selectedCurrency,
    required this.onCurrencySelected,
  }) : super(key: key);

  @override
  _CurrencySelectorState createState() => _CurrencySelectorState();
}

class _CurrencySelectorState extends State<CurrencySelector> {
  List<Currency> _currencies = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCurrencies();
  }

  Future<void> _loadCurrencies() async {
    try {
      final response = await CurrencyRatesService.getCurrencyRates();
      setState(() {
        _currencies = response.currencies;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(child: Text('Error: $_error'));
    }

    return DropdownButtonFormField<Currency>(
      value: widget.selectedCurrency,
      decoration: InputDecoration(
        labelText: 'Currency',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.attach_money),
      ),
      items: _currencies.map((currency) {
        return DropdownMenuItem<Currency>(
          value: currency,
          child: Row(
            children: [
              Text(
                currency.symbol,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(width: 8),
              Text('${currency.code} - ${currency.name}'),
            ],
          ),
        );
      }).toList(),
      onChanged: (Currency? newValue) {
        if (newValue != null) {
          widget.onCurrencySelected(newValue);
        }
      },
    );
  }
}

// ============================================================================
// CURRENCY CONVERTER SCREEN
// ============================================================================

class CurrencyConverterScreen extends StatefulWidget {
  @override
  _CurrencyConverterScreenState createState() =>
      _CurrencyConverterScreenState();
}

class _CurrencyConverterScreenState extends State<CurrencyConverterScreen> {
  List<Currency> _currencies = [];
  Currency? _fromCurrency;
  Currency? _toCurrency;
  bool _isLoading = true;
  String? _error;
  
  final TextEditingController _amountController = TextEditingController();
  double? _convertedAmount;

  @override
  void initState() {
    super.initState();
    _loadCurrencies();
  }

  Future<void> _loadCurrencies() async {
    try {
      final response = await CurrencyRatesService.getCurrencyRates();
      setState(() {
        _currencies = response.currencies;
        _isLoading = false;
        // Set USD as default from currency
        _fromCurrency = _currencies.firstWhere(
          (c) => c.code == 'USD',
          orElse: () => _currencies.first,
        );
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _convertCurrency() {
    if (_fromCurrency == null || _toCurrency == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select both currencies')),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    setState(() {
      _convertedAmount = CurrencyRatesService.convertCurrency(
        amount,
        _fromCurrency!,
        _toCurrency!,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Currency Converter'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadCurrencies,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Card(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Available Currencies',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 16),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _currencies.map((currency) {
                                  return Chip(
                                    avatar: Text(
                                      currency.symbol,
                                      style: TextStyle(fontSize: 16),
                                    ),
                                    label: Text(currency.code),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 24),
                      TextField(
                        controller: _amountController,
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Amount',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.money),
                        ),
                      ),
                      SizedBox(height: 16),
                      DropdownButtonFormField<Currency>(
                        value: _fromCurrency,
                        decoration: InputDecoration(
                          labelText: 'From Currency',
                          border: OutlineInputBorder(),
                        ),
                        items: _currencies.map((currency) {
                          return DropdownMenuItem(
                            value: currency,
                            child: Text('${currency.symbol} ${currency.code}'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _fromCurrency = value;
                            _convertedAmount = null;
                          });
                        },
                      ),
                      SizedBox(height: 16),
                      Icon(Icons.arrow_downward, size: 32, color: Colors.grey),
                      SizedBox(height: 16),
                      DropdownButtonFormField<Currency>(
                        value: _toCurrency,
                        decoration: InputDecoration(
                          labelText: 'To Currency',
                          border: OutlineInputBorder(),
                        ),
                        items: _currencies.map((currency) {
                          return DropdownMenuItem(
                            value: currency,
                            child: Text('${currency.symbol} ${currency.code}'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _toCurrency = value;
                            _convertedAmount = null;
                          });
                        },
                      ),
                      SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _convertCurrency,
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'CONVERT',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                      if (_convertedAmount != null) ...[
                        SizedBox(height: 24),
                        Card(
                          color: Colors.green.shade50,
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Text(
                                  'Converted Amount',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  _toCurrency!.formatAmount(_convertedAmount!),
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      SizedBox(height: 24),
                      Card(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Exchange Rates',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 16),
                              ..._currencies.map((currency) {
                                return ListTile(
                                  leading: Text(
                                    currency.symbol,
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  title: Text(
                                    '${currency.code} - ${currency.name}',
                                    style: TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  subtitle: Text(
                                    'Conversion Rate: ${currency.conversionRate}',
                                  ),
                                );
                              }).toList(),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }
}

// ============================================================================
// SIMPLE USAGE EXAMPLE
// ============================================================================

void simpleUsageExample() async {
  try {
    // 1. Fetch all currency rates
    final response = await CurrencyRatesService.getCurrencyRates();
    print('Loaded ${response.count} currencies');

    // 2. Get specific currency
    final usd = response.currencies.firstWhere((c) => c.code == 'USD');
    final eur = response.currencies.firstWhere((c) => c.code == 'EUR');
    final try = response.currencies.firstWhere((c) => c.code == 'TRY');

    // 3. Convert 100 USD to EUR
    final convertedToEur = CurrencyRatesService.convertCurrency(100, usd, eur);
    print('100 USD = ${eur.formatAmount(convertedToEur)}');

    // 4. Convert 100 USD to TRY (Turkish Lira)
    final convertedToTry = CurrencyRatesService.convertCurrency(100, usd, try);
    print('100 USD = ${try.formatAmount(convertedToTry)}');

    // 5. Convert 50 EUR to USD
    final convertedToUsd = CurrencyRatesService.convertCurrency(50, eur, usd);
    print('50 EUR = ${usd.formatAmount(convertedToUsd)}');

  } catch (e) {
    print('Error: $e');
  }
}

