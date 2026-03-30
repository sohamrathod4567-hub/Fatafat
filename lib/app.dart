import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/invoice_provider.dart';
import 'screens/billing_screen.dart';
import 'services/invoice_repository.dart';

class BillingApp extends StatelessWidget {
  const BillingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<InvoiceProvider>(
          create: (_) => InvoiceProvider(
            repository: InvoiceRepository(),
          )..loadInvoices(),
        ),
      ],
      child: MaterialApp(
        title: 'Billing App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF146C94),
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: const Color(0xFFF5F7FA),
          useMaterial3: true,
          cardTheme: const CardThemeData(
            elevation: 0,
            margin: EdgeInsets.zero,
          ),
          inputDecorationTheme: const InputDecorationTheme(
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        home: const BillingScreen(),
      ),
    );
  }
}
