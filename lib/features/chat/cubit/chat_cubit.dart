import 'package:bloc/bloc.dart';
import 'package:chat_app/features/chat/repos/chat_repos.dart';

part 'chat_state.dart';

class ChatCubit extends Cubit<ChatState> {
  ChatCubit(this.chatRepository) : super(ChatInitial());

  final ChatRepository chatRepository;
}
