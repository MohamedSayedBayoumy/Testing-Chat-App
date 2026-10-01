import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';

class CategoryBloc extends Bloc<CategoryEvent, CategoryState> {
  final ApiService _apiService;

  CategoryBloc(this._apiService) : super(CategoryInitial()) {
    
    on<FetchCategoryData>(
      _onFetchCategoryData,
    );
  }

  Future<void> _onFetchCategoryData(
    FetchCategoryData event,
    Emitter<CategoryState> emit,
  ) async {
    emit(CategoryLoading());
    try {
      final data = await _apiService.getCategoryById(event.categoryId);
      emit(CategoryLoaded(data));
    } catch (e) {
      emit(CategoryError(e.toString()));
    }
  }
}