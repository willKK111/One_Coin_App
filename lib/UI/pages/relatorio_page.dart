import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:testes_3unidade/provider/database_provider.dart';
import 'package:intl/intl.dart';

class RelatorioVendasPage extends StatefulWidget {
  @override
  _RelatorioVendasPageState createState() => _RelatorioVendasPageState();
}

class _RelatorioVendasPageState extends State<RelatorioVendasPage> {
  final List<String> _abas = ['Diário', 'Semanal', 'Mensal'];
  int _abaSelecionada = 0;

  Future<List<Map<String, dynamic>>> _carregarVendas(BuildContext context) async {
    final dbProvider = Provider.of<DatabaseProvider>(context, listen: false);
    final db = await dbProvider.database;
    final vendas = await db.query('vendas');

    return vendas;
  }

  DateTime? _converterHorario(String horario) {
    try {
      final format = DateFormat("dd/MM/yyyy HH:mm");
      return format.parse(horario);
    } catch (e) {
      print("Erro ao converter horário: $e");
      return null;
    }
  }

  Map<String, Map<String, dynamic>> _agruparVendas(
      List<Map<String, dynamic>> vendas) {
    final Map<String, Map<String, dynamic>> vendasAgrupadas = {};

    for (final venda in vendas) {
      final produtosJson = venda['produtos'];
      double total = 0.0;

      if (produtosJson != null && produtosJson is String) {
        final List<dynamic> produtos = jsonDecode(produtosJson);
        total = produtos.fold(0.0, (sum, produto) {
          final quantidade =
              int.tryParse(produto['quantidadeSelecionada'].toString()) ?? 0;
          final preco = double.tryParse(produto['preco'].toString()) ?? 0.0;
          return sum + (quantidade * preco);
        });
      }

      DateTime? dataVenda;
      final horario = venda['horario'];

      if (horario != null && horario is String) {
        dataVenda = _converterHorario(horario);
        if (dataVenda == null) continue;
      } else {
        print("Horário ausente ou inválido na venda: $venda");
        continue;
      }

      String chaveAgrupamento;
      if (_abaSelecionada == 0) {
        chaveAgrupamento =
        '${dataVenda.year}-${dataVenda.month.toString().padLeft(2, '0')}-${dataVenda.day.toString().padLeft(2, '0')}';
      } else if (_abaSelecionada == 1) {
        final primeiraSemana = dataVenda.subtract(
            Duration(days: dataVenda.weekday - 1));
        chaveAgrupamento =
        'Semana ${primeiraSemana.day}/${primeiraSemana.month}/${primeiraSemana.year}';
      } else {
        chaveAgrupamento =
        '${dataVenda.year}-${dataVenda.month.toString().padLeft(2, '0')}';
      }

      vendasAgrupadas[chaveAgrupamento] ??= {'total': 0.0, 'vendas': []};
      vendasAgrupadas[chaveAgrupamento]!['total'] += total;
      vendasAgrupadas[chaveAgrupamento]!['vendas'].add(venda);
    }

    return vendasAgrupadas;
  }

  Future<String> _gerarPDF(Map<String, Map<String, dynamic>> vendasAgrupadas) async {
    final pdf = pw.Document();
    double totalGeral = 0.0;

    pdf.addPage(pw.Page(
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Relatório de Vendas', style: pw.TextStyle(fontSize: 24)),
            pw.SizedBox(height: 16),
            ...vendasAgrupadas.entries.map((entry) {
              final periodo = entry.key;
              final vendas = entry.value['vendas'];
              final totalPeriodo = entry.value['total'];

              totalGeral += totalPeriodo; // Soma o total do período ao total geral

              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Período: $periodo', style: pw.TextStyle(fontSize: 18)),
                  pw.Text('Total do Período: R\$ ${totalPeriodo.toStringAsFixed(2)}'),
                  pw.SizedBox(height: 8),
                  pw.Bullet(text: 'Vendas:'),
                  pw.Column(
                    children: vendas.map<pw.Widget>((venda) {
                      final produtosJson = venda['produtos'];
                      double totalVenda = 0.0;

                      if (produtosJson != null && produtosJson is String) {
                        final List<dynamic> produtos = jsonDecode(produtosJson);
                        totalVenda = produtos.fold(0.0, (sum, produto) {
                          final quantidade = int.tryParse(
                              produto['quantidadeSelecionada'].toString()) ??
                              0;
                          final preco = double.tryParse(produto['preco'].toString()) ?? 0.0;
                          return sum + (quantidade * preco);
                        });
                      }

                      return pw.Text(
                          'Venda #${venda['id']} - R\$ ${totalVenda.toStringAsFixed(2)}');
                    }).toList(),
                  ),
                  pw.SizedBox(height: 16),
                ],
              );
            }),
            pw.Divider(),
            pw.Text('Total Geral: R\$ ${totalGeral.toStringAsFixed(2)}',
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          ],
        );
      },
    ));

    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/relatorio_vendas.pdf';
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());

    return filePath;
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _abas.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Relatório de Vendas", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey.shade300)),
          centerTitle: true,
          backgroundColor: Color(0xFF00897B),
          bottom: TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            onTap: (index) {
              setState(() {
                _abaSelecionada = index;
              });
            },
            tabs: _abas.map((aba) => Tab(text: aba)).toList(),
          ),
        ),
        body: FutureBuilder<List<Map<String, dynamic>>>(
          future: _carregarVendas(context),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return const Center(child: Text('Nenhuma venda encontrada.'));
            }

            final vendas = snapshot.data!;
            if (vendas.isEmpty) {
              return const Center(child: Text('Nenhuma venda disponível.'));
            }

            final vendasAgrupadas = _agruparVendas(vendas);

            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: vendasAgrupadas.keys.length,
                    itemBuilder: (context, index) {
                      final periodo = vendasAgrupadas.keys.elementAt(index);
                      final total = vendasAgrupadas[periodo]!['total'];

                      return Card(
                        margin: EdgeInsets.all(8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 8,
                        color: Color(0xFF4DB6AC),
                        child: ListTile(
                          title: Text(
                            'Período: $periodo',
                            style: TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            'Total: R\$ ${total.toStringAsFixed(2)}',
                            style: TextStyle(color: Colors.white70),
                          ),
                          onTap: () async {
                            final filePath =
                            await _gerarPDF({periodo: vendasAgrupadas[periodo]!});
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ViewPdf(filePath),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF00796B), // Cor de fundo do botão
                      padding: EdgeInsets.symmetric(vertical: 14.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.picture_as_pdf, color: Colors.white,),
                    label: const Text('Gerar PDF Completo', style: TextStyle(fontSize: 18, color: Colors.white)),
                    onPressed: () async {
                      final filePath = await _gerarPDF(vendasAgrupadas);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ViewPdf(filePath),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class ViewPdf extends StatelessWidget {
  final String path;

  const ViewPdf(this.path, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Visualizar PDF'),
        backgroundColor: Color(0xFF00796B),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              Share.shareXFiles([XFile(path)], subject: "Relatório de Vendas");
            },
          ),
        ],
      ),
      body: PDFView(
        filePath: path,
        onError: (error) {
          debugPrint("Erro ao carregar PDF: $error");
        },
        onPageError: (page, error) {
          debugPrint("Erro na página $page: $error");
        },
      ),
    );
  }
}
