import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:testes_3unidade/UI/widgets/buildTextField.dart';
import 'package:testes_3unidade/provider/database_provider.dart';
import 'pdf_page.dart';

class CadastroVendas extends StatefulWidget {
  @override
  _CadastroVendasState createState() => _CadastroVendasState();
}

class _CadastroVendasState extends State<CadastroVendas> {
  late DatabaseProvider _databaseProvider;
  final List<Map<String, dynamic>> _produtosSelecionados = [];
  String _metodoPagamento = 'Dinheiro';
  final Map<int, TextEditingController> _quantidadeControllers = {};
  TextEditingController _nomeController = TextEditingController();
  TextEditingController _cpfController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _databaseProvider = Provider.of<DatabaseProvider>(context);
  }

  Future<List<Map<String, dynamic>>> _carregarEstoque() async {
    final db = await _databaseProvider.database;
    return await db.query('estoque');
  }

  void _adicionarProduto(Map<String, dynamic> produto) {
    final id = produto['id'] as int;
    final quantidade = _quantidadeControllers[id]?.text ?? '0';
    final quantidadeInt = int.tryParse(quantidade) ?? 0;

    if (quantidadeInt <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Selecione uma quantidade válida!',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: EdgeInsets.symmetric(horizontal: 20, vertical: 100),
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      );

      return;
    }

    setState(() {
      _produtosSelecionados.add({
        'id': id,
        'produto': produto['produto'] ?? 'Produto desconhecido',
        'quantidadeSelecionada': quantidade,
        'preco': produto['preco'] ?? 0.0,
      });
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${produto['produto']} adicionado a venda',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: EdgeInsets.symmetric(horizontal: 20, vertical: 100),
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    );

  }

  Future<void> _atualizarEstoque() async {
    final db = await _databaseProvider.database;

    for (var produto in _produtosSelecionados) {
      final id = produto['id'] as int;
      final quantidadeSelecionada = int.parse(produto['quantidadeSelecionada']);

      final resultado = await db.query(
        'estoque',
        columns: ['quantidade'],
        where: 'id = ?',
        whereArgs: [id],
      );

      if (resultado.isNotEmpty) {
        final quantidadeAtual = resultado.first['quantidade'] as int;
        final novaQuantidade = quantidadeAtual - quantidadeSelecionada;

        await db.update(
          'estoque',
          {'quantidade': novaQuantidade},
          where: 'id = ?',
          whereArgs: [id],
        );
      }
    }
  }

  String formatarDataEHora(DateTime dateTime) {
    return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
  }

  Future<void> registrarVenda() async {
    final db = await _databaseProvider.database;
    final horario = formatarDataEHora(DateTime.now());
    final nomeCliente = _nomeController.text;
    final cpfCliente = _cpfController.text.isNotEmpty ? _cpfController.text : 'Não informado';

    // Converte a lista de produtos em formato JSON
    String produtosJson = jsonEncode(_produtosSelecionados);

    // Inserir a venda com a lista de produtos em formato JSON
    await db.insert('vendas', {
      'produtos': produtosJson,  // Lista de produtos em formato JSON
      'metodoPagamento': _metodoPagamento,
      'horario': horario,
      'nome': nomeCliente,
      'cpf': cpfCliente,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Venda registrado com sucesso',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: EdgeInsets.symmetric(horizontal: 20, vertical: 100),
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    );

    Provider.of<DatabaseProvider>(context, listen: false).exportToFirebaseDatabase();
  }

  void _limparCampos() {
    _nomeController.clear();
    _cpfController.clear();
    _quantidadeControllers.forEach((key, controller) {
      controller.clear();
    });
    _quantidadeControllers.clear();
  }

  void _gerarPdfEAtualizarEstoque() async {
    if (_produtosSelecionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Nenhum produto selecionado',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: EdgeInsets.symmetric(horizontal: 20, vertical: 100),
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      );
      return;
    }

    if (_nomeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'O nome do cliente é obrigatório',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: EdgeInsets.symmetric(horizontal: 20, vertical: 100),
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      );
      return;
    }

    try {
      // Atualizar o estoque no banco de dados
      await _atualizarEstoque();

      // Registrar a venda no banco de dados
      await registrarVenda();

      _limparCampos();

      // Navegar para a página do PDF
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PdfPage(
            produtos: _produtosSelecionados,
            metodoPagamento: _metodoPagamento,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erro ao atualizar o estoque',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: EdgeInsets.symmetric(horizontal: 20, vertical: 100),
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal.shade700,
        title: Text("Cadastro de Vendas", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey.shade300)),
        centerTitle: true,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _carregarEstoque(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text('Erro ao carregar o estoque'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Estoque vazio'));
          }

          final produtos = snapshot.data!;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                buildTextField(
                  controller: _nomeController,
                  label: 'Nome do Cliente*',
                  hintText: 'Digite o nome completo',
                    keyboardType: TextInputType.text
                ),
                const SizedBox(height: 8),
                buildTextField(
                  controller: _cpfController,
                  label: 'CPF do Cliente (Opcional)',
                  hintText: 'Digite o CPF (se disponível)',
                  keyboardType: TextInputType.text
                ),
                const SizedBox(height: 16),
                Text(
                  'Selecione os Produtos:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal.shade900),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    itemCount: produtos.length,
                    itemBuilder: (context, index) {
                      final produto = produtos[index];
                      final id = produto['id'] as int;
                      final nome = produto['produto'] ?? 'Produto desconhecido';
                      final preco = produto['preco']?.toStringAsFixed(2) ?? '0.00';
                      final estoque = produto['quantidade'] ?? 0;

                      if (!_quantidadeControllers.containsKey(id)) {
                        _quantidadeControllers[id] = TextEditingController(text: '');
                      }

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.teal.shade300),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ListTile(
                            title: Text(nome, style: TextStyle(color: Colors.teal.shade900)),
                            subtitle: Text('Preço: R\$ $preco | Estoque: $estoque'),
                            trailing: SizedBox(
                              width: 100,
                              child: TextField(
                                controller: _quantidadeControllers[id],
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Qtd.',
                                  labelStyle: TextStyle(color: Colors.teal.shade900),
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            onTap: () {
                              final quantidade = _quantidadeControllers[id]?.text ?? '0';

                              if (int.tryParse(quantidade) != null &&
                                  int.parse(quantidade) > 0 &&
                                  int.parse(quantidade) <= estoque) {
                                _adicionarProduto(produto);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Selecione uma quantidade válida',
                                      style: TextStyle(color: Colors.white, fontSize: 16),
                                    ),
                                    backgroundColor: Colors.redAccent,
                                    behavior: SnackBarBehavior.floating,
                                    duration: Duration(seconds: 2),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    margin: EdgeInsets.symmetric(horizontal: 20, vertical: 100),
                                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
                DropdownButton<String>(
                  value: _metodoPagamento,
                  onChanged: (value) {
                    setState(() {
                      _metodoPagamento = value!;
                    });
                  },
                  items: const [
                    DropdownMenuItem(value: 'Dinheiro', child: Text('Dinheiro')),
                    DropdownMenuItem(value: 'Cartão', child: Text('Cartão')),
                    DropdownMenuItem(value: 'Pix', child: Text('Pix')),
                  ],
                  style: TextStyle(color: Colors.teal.shade700),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _gerarPdfEAtualizarEstoque,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade700,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FaIcon(FontAwesomeIcons.print, color: Colors.white),
                      const SizedBox(width: 8),
                      const Text(
                        'Gerar PDF e Finalizar',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _cpfController.dispose();
    for (var controller in _quantidadeControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
}
