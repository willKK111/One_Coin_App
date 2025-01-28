import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pdfLib;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';


class PdfPage extends StatelessWidget {
  final List<Map<String, dynamic>> produtos;
  final String metodoPagamento;

  const PdfPage({
    Key? key,
    required this.produtos,
    required this.metodoPagamento,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Comprovante", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey.shade300)),
        centerTitle: true,
        backgroundColor: Color(0xFF00897B),
      ),
      body: Container(
        color: Colors.teal[50],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: produtos.length,
                itemBuilder: (context, index) {
                  final produto = produtos[index];
                  final nomeProduto = produto['produto'] ?? 'Produto desconhecido';
                  final quantidade = int.tryParse(produto['quantidadeSelecionada'].toString()) ?? 0;
                  final preco = double.tryParse(produto['preco'].toString()) ?? 0.0;
                  final total = quantidade * preco;

                  return Card(
                    color: Colors.white,
                    margin: const EdgeInsets.all(8.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Produto: $nomeProduto',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text('Preço: R\$ ${preco.toStringAsFixed(2)}'),
                          Text('Quantidade: $quantidade'),
                          Text('Total: R\$ ${total.toStringAsFixed(2)}'),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Método de Pagamento: $metodoPagamento',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  _createPdf(context, produtos, metodoPagamento);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                child: const Text('Criar PDF', style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _createPdf(
      BuildContext context,
      List<Map<String, dynamic>> produtos,
      String metodoPagamento,
      ) async {
    final pdfLib.Document pdf = pdfLib.Document();

    double valorTotalCompra = 0.0;
    List<List<String>> tabelaProdutos = [
      ['Descrição', 'Qtd', 'Preço Unitário', 'Valor Total'],
    ];

    for (var produto in produtos) {
      final nome = produto['produto'] ?? 'Produto desconhecido';
      final quantidade = int.tryParse(produto['quantidadeSelecionada'].toString()) ?? 0;
      final preco = double.tryParse(produto['preco'].toString()) ?? 0.0;
      final total = quantidade * preco;
      valorTotalCompra += total;

      tabelaProdutos.add([
        nome,
        quantidade.toString(),
        'R\$ ${preco.toStringAsFixed(2)}',
        'R\$ ${total.toStringAsFixed(2)}',
      ]);
    }

    pdf.addPage(pdfLib.MultiPage(
      build: (context) => [
        pdfLib.Header(
          level: 0,
          child: pdfLib.Text(
            'Comprovante de Venda',
            style: pdfLib.TextStyle(fontSize: 24),
          ),
        ),
        pdfLib.SizedBox(height: 20),
        pdfLib.Table.fromTextArray(
          context: context,
          headerStyle: pdfLib.TextStyle(fontWeight: pdfLib.FontWeight.bold),
          headers: tabelaProdutos[0],
          data: tabelaProdutos.sublist(1),
        ),
        pdfLib.SizedBox(height: 20),
        pdfLib.Text(
          'Método de Pagamento: $metodoPagamento',
          style: pdfLib.TextStyle(fontSize: 16),
        ),
        pdfLib.SizedBox(height: 10),
        pdfLib.Text(
          'Total do Recibo: R\$ ${valorTotalCompra.toStringAsFixed(2)}',
          style: pdfLib.TextStyle(fontSize: 18, fontWeight: pdfLib.FontWeight.bold),
        ),
      ],
    ));

    final String dir = (await getApplicationDocumentsDirectory()).path;
    final String path = '$dir/Comprovante.pdf';
    final File file = File(path);
    await file.writeAsBytes(await pdf.save());

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ViewPdf(path)),
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
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              Share.shareXFiles([XFile(path)], subject: "Comprovante de Venda");
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
