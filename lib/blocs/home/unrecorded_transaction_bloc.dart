import 'dart:async';

import 'package:mpesa_ledger_flutter/blocs/base_bloc.dart';
import 'package:mpesa_ledger_flutter/blocs/home/home_bloc.dart';
import 'package:mpesa_ledger_flutter/repository/unrecorded_transactions_repository.dart';
import 'package:mpesa_ledger_flutter/services/sms_filter/index.dart';

class UnrecordedTransactionsBloc extends BaseBloc {
  SMSFilter _smsFilter = SMSFilter();

  bool insertTransactions = true;

  UnrecordedTransactionsRepository _unrecordedTransactionsRepository =
      UnrecordedTransactionsRepository();

  // EVENTS

  StreamController _insertTransactionsEvent = StreamController();
  Stream get insertTransactionsEventStream => _insertTransactionsEvent.stream;
  StreamSink get insertTransactionsEventSink => _insertTransactionsEvent.sink;
  
  StreamController<bool> _showFetchEvent = StreamController<bool>.broadcast();
  Stream<bool> get showFetchEventStream => _showFetchEvent.stream;
  StreamSink<bool> get showFetchEventSink => _showFetchEvent.sink;

  UnrecordedTransactionsBloc() {
    insertTransactionsEventStream.listen((void data) {
      _insertTrasanctions();
    });
    showFetchEventStream.listen((bool data) {
      print("showing from bloc $data");
    });
  }

  _insertTrasanctions() async {
    if (insertTransactions) {
      insertTransactions = false;
      var result = await _getTransactions();
      if (result.isNotEmpty) {
        showFetchEventSink.add(true);
        await _smsFilter.addSMSTodatabase(result.reversed.toList());
        showFetchEventSink.add(false);
        for (var i = 0; i < result.length; i++) {
          await _deleteTransaction(result[i]["id"].toString());
        }
        homeBloc.getSMSDataEventSink.add(10);
      }
      insertTransactions = true;
    }
  }

  Future<List<dynamic>> _getTransactions() async {
    List<Map<dynamic, dynamic>> listMap = [];
    var result = await _unrecordedTransactionsRepository.select();
    for (var i = 0; i < result.length; i++) {
      listMap.add(result[i].toMap());
    }
    return listMap;
  }

  _deleteTransaction(String id) async {
    await _unrecordedTransactionsRepository.delete(id);
  }

  @override
  void dispose() {
    _insertTransactionsEvent.close();
    _showFetchEvent.close();
  }
}

UnrecordedTransactionsBloc unrecordedTransactionsBloc = UnrecordedTransactionsBloc();