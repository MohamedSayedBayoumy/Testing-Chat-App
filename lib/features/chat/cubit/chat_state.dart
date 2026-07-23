part of 'chat_cubit.dart';

sealed class ChatState {}

final class ChatInitial extends ChatState {}

final class MessageSending extends ChatState {}

final class MessageSended extends ChatState {}

final class MessageFailed extends ChatState {
  final String errorMessage;

  MessageFailed(this.errorMessage);
}

final class WaitingForResponse extends ChatState {}

