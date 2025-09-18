import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mdbuddy/bloc/markdown_line_style_bloc.dart';
import 'package:mdbuddy/screens/markdown_editor/martdown_editor_screen.dart';
import 'package:window_manager/window_manager.dart';

import '../../main.dart';
import '../../utils/key_handler.dart';
import 'components/markdown_input.dart';

class MarkdownEditorState extends State<MarkdownEditor> {
  double _dragPosition = 100.0;

  final TextEditingController _controller = TextEditingController();
  final KeyHandler _keyHandler = KeyHandler();

  @override
  void initState() {
    super.initState();
    _keyHandler.initKeyboardListener(_controller);
  }

  @override
  void dispose() {
    _keyHandler.disposeKeyboardListener();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<MarkdownLineStyleBloc>(
      create: (context) => MarkdownLineStyleBloc(), // Bloc 인스턴스 생성
      child: Scaffold(
        appBar: PreferredSize(
          // AppBar의 높이 조절
          preferredSize: Size.fromHeight(20.0),
          child: GestureDetector(
            // AppBar 전체 영역을 창 이동에 사용 (데스크톱 전용)
            onPanStart: isDesktop()
                ? (details) {
                    windowManager.startDragging();
                  }
                : null,
            child: AppBar(
              backgroundColor: Colors.white,
              flexibleSpace: SafeArea(
                child: Stack(
                  children: [
                    // 드래그 가능한 영역
                    Positioned(
                      left: _dragPosition,
                      top: 0,
                      bottom: 0,
                      child: GestureDetector(
                        onHorizontalDragUpdate: (details) {
                          setState(() {
                            // 화면 범위 내에서만 이동 가능하도록 제한
                            double newPosition =
                                _dragPosition + details.delta.dx;
                            if (newPosition >= 0 &&
                                newPosition <=
                                    MediaQuery.of(context).size.width - 50) {
                              _dragPosition = newPosition;
                            }
                          });
                        },
                        child: Container(
                          // 명시적인 너비 설정
                          width: 50.0, // 예시 너비
                          color: Colors.transparent, // 필요하다면 배경색 설정
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: BlocBuilder<MarkdownLineStyleBloc, MarkdownLineStyleState>(
          builder: (context, state) {
            final lineStyles = state.lineStyles;
            return Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                        32.0, 24.0, 32.0, 24.0), // 4방향 margin 추가
                    child: LineStyledTextField(
                      controller: _controller,
                      lineStyles: lineStyles,
                      onChanged: (text) {
                        setState(() {});
                      },
                    ),
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
