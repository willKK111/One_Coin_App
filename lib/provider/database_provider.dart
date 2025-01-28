import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:firebase_database/firebase_database.dart'; // Import do Firebase Realtime Database
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseProvider with ChangeNotifier {
  Database? _database;

  // Instância do Firebase Realtime Database
  final DatabaseReference _firebaseRef = FirebaseDatabase.instance.ref();

  // Obter instância do banco de dados
  Future<Database> get database async {
    if (_database != null) return _database!;

    // Cria ou abre o banco de dados
    _database = await _initializeDatabase();
    return _database!;
  }

  // Inicializa o banco de dados SQLite
  Future<Database> _initializeDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'app_database.db');

    return await openDatabase(
      path,
      version: 3,
      onCreate: (db, version) async {
        // Criação das tabelas
        await db.execute('''
          CREATE TABLE estoque(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            produto TEXT NOT NULL,
            quantidade INTEGER NOT NULL,
            preco REAL NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE vendas(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            produtos TEXT NOT NULL,
            metodoPagamento TEXT NOT NULL,
            horario TEXT NOT NULL,
            nome TEXT NOT NULL,
            cpf TEXT NOT NULL
          )
        ''');
      },
    );
  }

  // Exportar dados do SQLite para o Firebase Realtime Database
  Future<void> exportToFirebaseDatabase() async {
    try {
      final db = await database;

      // Recupera os dados das tabelas
      final estoqueData = await db.query('estoque');
      final vendasData = await db.query('vendas');

      // Envia os dados para o Firebase
      await _firebaseRef.child('backup/estoque').set(estoqueData);
      await _firebaseRef.child('backup/vendas').set(vendasData);

      print('Dados exportados com sucesso para o Firebase Realtime Database.');
    } catch (e) {
      print('Erro ao exportar para o Firebase Realtime Database: $e');
    }
  }

  // Importar dados do Firebase Realtime Database para o SQLite
  Future<void> importFromFirebaseDatabase() async {
    try {
      final db = await database;

      // Obtém os dados do Firebase Realtime Database
      final estoqueSnapshot = await _firebaseRef.child('backup/estoque').get();
      final vendasSnapshot = await _firebaseRef.child('backup/vendas').get();

      if (estoqueSnapshot.exists && vendasSnapshot.exists) {
        final List<dynamic> estoqueData = estoqueSnapshot.value as List<dynamic>;
        final List<dynamic> vendasData = vendasSnapshot.value as List<dynamic>;

        // Atualiza o banco de dados SQLite com os dados
        final batch = db.batch();

        // Atualiza tabela `estoque`
        for (var item in estoqueData) {
          batch.insert(
            'estoque',
            Map<String, dynamic>.from(item),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }

        // Atualiza tabela `vendas`
        for (var item in vendasData) {
          batch.insert(
            'vendas',
            Map<String, dynamic>.from(item),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }

        await batch.commit();
        print('Banco de dados atualizado com sucesso a partir do Firebase Realtime Database.');
      } else {
        print('Nenhum dado encontrado no Firebase Realtime Database.');
      }
    } catch (e) {
      print('Erro ao importar do Firebase Realtime Database: $e');
    }
  }

  Future<void> deleteFromFirebaseProduto(int produtoId) async {
    try {
      final id = produtoId - 1;
      await _firebaseRef.child('backup/estoque/$id').remove();
      print('Produto $produtoId excluído do Firebase com sucesso!');
    } catch (e) {
      print('Erro ao excluir o produto do Firebase: $e');
      throw Exception('Erro ao excluir o produto do Firebase');
    }
  }

  // Função para excluir uma venda do Firebase e SQLite
  Future<void> deleteVenda(int vendaId) async {
    try {
      // Deletar do Firebase
      await deleteFromFirebaseVenda(vendaId);

      // Deletar do SQLite
      await deleteFromSQLite(vendaId);

      print('Venda excluída com sucesso do Firebase e do SQLite!');
    } catch (e) {
      print('Erro ao excluir a venda: $e');
      throw Exception('Erro ao excluir a venda');
    }
  }

  // Função para excluir a venda do Firebase
  Future<void> deleteFromFirebaseVenda(int vendaId) async {
    try {
      final vendaFinal = vendaId-1;
      final vendaRef = _firebaseRef.child('backup/vendas/$vendaFinal');
      await vendaRef.remove();
      print('Venda $vendaId excluída do Firebase com sucesso!');
    } catch (e) {
      print('Erro ao excluir a venda do Firebase: $e');
      throw Exception('Erro ao excluir a venda do Firebase');
    }
  }

  // Função para excluir a venda do SQLite
  Future<void> deleteFromSQLite(int vendaId) async {
    try {
      final db = await database;
      await db.delete(
        'vendas',
        where: 'id = ?',
        whereArgs: [vendaId],
      );
      print('Venda $vendaId excluída do SQLite com sucesso!');
    } catch (e) {
      print('Erro ao excluir a venda do SQLite: $e');
      throw Exception('Erro ao excluir a venda do SQLite');
    }
  }

}
