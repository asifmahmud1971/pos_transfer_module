import 'package:equatable/equatable.dart';
import 'package:flutter_pos_transfer/features/transfer/model/transfer_item.dart';

class TransferState extends Equatable {
  final List<TransferItem> transfers;
  final String? errorMessage;

  const TransferState({
    this.transfers = const [],
    this.errorMessage,
  });

  List<TransferItem> get activeTransfers => transfers.where((t) =>
  t.status == TransferStatus.inProgress ||
      t.status == TransferStatus.pending
  ).toList();

  List<TransferItem> get completedTransfers => transfers.where((t) =>
  t.status == TransferStatus.completed
  ).toList();

  List<TransferItem> get failedTransfers => transfers.where((t) =>
  t.status == TransferStatus.failed
  ).toList();

  TransferItem? getTransferById(String id) {
    try {
      return transfers.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }

  TransferState copyWith({
    List<TransferItem>? transfers,
    String? errorMessage,
  }) {
    return TransferState(
      transfers: transfers ?? this.transfers,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [transfers, errorMessage];
}