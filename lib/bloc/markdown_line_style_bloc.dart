import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:mdbuddy/utils/markdown_line_style_provider.dart';

// 1. Event 정의
abstract class MarkdownLineStyleEvent extends Equatable {
  const MarkdownLineStyleEvent();

  @override
  List<Object> get props => [];
}

// LineStyle을 특정 인덱스에 추가하는 이벤트
class AddLineStyleEvent extends MarkdownLineStyleEvent {
  final LineStyle style;
  final int index; // 스타일을 추가할 인덱스

  const AddLineStyleEvent({
    required this.style,
    required this.index
  });

  @override
  List<Object> get props => [style, index];
}

// LineStyle을 특정 인덱스에 삽입하는 이벤트 (기존 스타일들을 뒤로 밀어냄)
class InsertLineStyleEvent extends MarkdownLineStyleEvent {
  final LineStyle style;
  final int index;

  const InsertLineStyleEvent({
    required this.style,
    required this.index
  });

  @override
  List<Object> get props => [style, index];
}

// LineStyle을 제거하는 이벤트
class RemoveLineStyleEvent extends MarkdownLineStyleEvent {
  final int index;

  const RemoveLineStyleEvent(this.index);

  @override
  List<Object> get props => [index];
}

// 모든 스타일을 초기화하는 이벤트
class ResetLineStylesEvent extends MarkdownLineStyleEvent {}

// 2. State 정의
class MarkdownLineStyleState extends Equatable {
  final List<LineStyle> lineStyles;

  const MarkdownLineStyleState({required this.lineStyles});

  factory MarkdownLineStyleState.initial() => MarkdownLineStyleState(
      lineStyles: [LineStyleProvider.getLineStyle(MarkdownLineStyles.normal)]
  );

  MarkdownLineStyleState copyWith({List<LineStyle>? lineStyles}) {
    return MarkdownLineStyleState(
      lineStyles: lineStyles ?? this.lineStyles,
    );
  }

  @override
  List<Object> get props => [lineStyles];
}

// 3. BLoC 구현
class MarkdownLineStyleBloc extends Bloc<MarkdownLineStyleEvent, MarkdownLineStyleState> {
  MarkdownLineStyleBloc() : super(MarkdownLineStyleState.initial()) {
    on<AddLineStyleEvent>(_addLineStyle);
    on<InsertLineStyleEvent>(_insertLineStyle);
    on<RemoveLineStyleEvent>(_removeLineStyle);
    on<ResetLineStylesEvent>(_resetLineStyles);
  }

  void _addLineStyle(AddLineStyleEvent event, Emitter<MarkdownLineStyleState> emit) {
    final updatedStyles = List<LineStyle>.from(state.lineStyles);

    // 인덱스 검증
    if (event.index < 0) {
      // 음수 인덱스의 경우 리스트 맨 앞에 추가
      updatedStyles.insert(0, event.style);
    } else if (event.index >= updatedStyles.length) {

      // 리스트 크기보다 큰 인덱스의 경우
      final existingLength = updatedStyles.length;
      final diff = event.index - existingLength;

      // 필요한 만큼 기본 스타일 추가
      for (int i = 0; i < diff; i++) {
        updatedStyles.add(LineStyleProvider.getLineStyle(MarkdownLineStyles.normal));
      }

      // 맨 뒤에 새로운 스타일 추가
      updatedStyles.add(event.style);
    } else {
      // 정해진 인덱스의 스타일을 변경함
      updatedStyles[event.index] = event.style;
    }

    emit(state.copyWith(lineStyles: updatedStyles));
  }

  void _insertLineStyle(InsertLineStyleEvent event, Emitter<MarkdownLineStyleState> emit) {
    final updatedStyles = List<LineStyle>.from(state.lineStyles);
    
    if (event.index < 0) {
      updatedStyles.insert(0, event.style);
    } else if (event.index >= updatedStyles.length) {
      updatedStyles.add(event.style);
    } else {
      updatedStyles.insert(event.index, event.style);
    }
    
    emit(state.copyWith(lineStyles: updatedStyles));
  }

  void _removeLineStyle(RemoveLineStyleEvent event, Emitter<MarkdownLineStyleState> emit) {
    // 인덱스가 유효한지 확인
    if (event.index >= 0 && event.index < state.lineStyles.length) {
      final updatedStyles = List<LineStyle>.from(state.lineStyles);
      updatedStyles.removeAt(event.index);
      emit(state.copyWith(lineStyles: updatedStyles));
    }
  }

  void _resetLineStyles(ResetLineStylesEvent event, Emitter<MarkdownLineStyleState> emit) {
    // 기본 스타일로 초기화
    emit(MarkdownLineStyleState.initial());
  }
}
