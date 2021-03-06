﻿CompilerIf #PB_Compiler_OS = #PB_OS_MacOS 
 ; IncludePath "/Users/as/Documents/GitHub/Widget/"
CompilerElseIf #PB_Compiler_OS = #PB_OS_Windows
  ;  IncludePath "/Users/as/Documents/GitHub/Widget/"
CompilerElseIf #PB_Compiler_OS = #PB_OS_Linux
  ;  IncludePath "/Users/a/Documents/GitHub/Widget/"
CompilerEndIf

CompilerIf #PB_Compiler_IsMainFile
  XIncludeFile "module_draw.pbi"
  
  XIncludeFile "module_macros.pbi"
  XIncludeFile "module_constants.pbi"
  XIncludeFile "module_structures.pbi"
  XIncludeFile "module_scroll.pbi"
  XIncludeFile "module_text.pbi"
  XIncludeFile "module_editor.pbi"
  
  CompilerIf #VectorDrawing
    UseModule Draw
  CompilerEndIf
CompilerEndIf

DeclareModule ListView
  EnableExplicit
  UseModule Macros
  UseModule Constants
  UseModule Structures
  
  CompilerIf #VectorDrawing
    UseModule Draw
  CompilerEndIf
  
  
  ;- - DECLAREs MACROs
  Macro GetText(_this_) : Text::GetText(_this_) : EndMacro
  Macro CountItems(_this_) : Editor::CountItems(_this_) : EndMacro
  Macro ClearItems(_this_) : Editor::ClearItems(_this_) : EndMacro
  Macro SetText(_this_, _text_) : Editor::SetText(_this_,_text_,0) : EndMacro
  Macro RemoveItem(_this_, _item_) : Editor::RemoveItem(_this_, _item_) : EndMacro
  Macro SetFont(_this_, _font_id_) : Editor::SetFont(_this_, _font_id_) : EndMacro
  Macro Resize(_adress_, _x_,_y_,_width_,_height_) : Text::Resize(_adress_, _x_,_y_,_width_,_height_) : EndMacro
  Macro AddItem(_this_, _item_,_text_,_image_=-1,_flag_=0) : Editor::AddItem(_this_,_item_,_text_,_image_,_flag_) : EndMacro
  
  ;- DECLAREs PROCEDUREs
  Declare.i GetState(*This.Widget_S)
  Declare.i SetState(*This.Widget_S, State.i)
  ; Declare.i GetItemState(*This.Widget_S, Item.i)
  Declare.i SetItemState(*This.Widget_S, Item.i, State.i)
  Declare.i CallBack(*This.Widget_S, EventType.i, Canvas.i=-1, CanvasModifiers.i=-1)
  Declare.i Create(Canvas.i, Widget, X.i, Y.i, Width.i, Height.i, Text.s, Flag.i=0, Radius.i=0)
  Declare.i Gadget(Gadget.i, X.i, Y.i, Width.i, Height.i, Flag.i=0)
EndDeclareModule

Module ListView
  ;-
  ;- PROCEDUREs
  ;-
  Procedure.i SetItemState(*This.Widget_S, Item.i, State.i)
    Protected Result
    
    With *This
      If (\Flag\MultiSelect Or \Flag\ClickSelect)
        PushListPosition(\items())
        Result = SelectElement(\items(), Item) 
        If Result 
          \items()\index[1] = \items()\index
          \items()\Color\State = Bool(State)+1
        EndIf
        PopListPosition(\items())
      EndIf
    EndWith
    
    ProcedureReturn Result
  EndProcedure
  
  Procedure.i SetState(*This.Widget_S, State.i)
    With *This
      Text::Redraw(*This, \Canvas\Gadget)
      
      PushListPosition(\items())
      SelectElement(\items(), State) : \items()\Focus = State : \items()\index[1] = \items()\index : \items()\Color\State = 2
      ; Scroll::SetState(\Scroll\v, ((State*\Text\Height)-\Scroll\v\Height) + \Text\Height) ;: \Scroll\Y =- \Scroll\v\page\Pos ; в конце
      ; Scroll::SetState(\Scroll\v, (State*\Text\Height)) ;: \Scroll\Y =- \Scroll\v\page\Pos ; в начале 
        Scroll::SetState(\Scroll\v, ((\items()\y-\text\y)-(\Height[2]-\items()\height))) ; в конце
       ; Scroll::SetState(\Scroll\v, \items()\y-\text\y) ; в начале
      PopListPosition(\items())
    EndWith
  EndProcedure
  
  Procedure.i GetState(*This.Widget_S)
    Protected Result
    
    With *This
      PushListPosition(\items())
      ForEach \items()
        If \items()\Focus = \items()\index
          Result = \items()\index
        EndIf
      Next
      PopListPosition(\items())
    EndWith
    
    ProcedureReturn Result
  EndProcedure
  
  Procedure.i Events(*This.Widget_S, EventType.i)
    Static DoubleClick.i
    Protected Repaint.i, Control.i, Caret.i, Item.i, String.s
    
    With *This
      Repaint | Scroll::CallBack(\Scroll\v, EventType, \Canvas\Mouse\X, \Canvas\Mouse\Y)
      Repaint | Scroll::CallBack(\Scroll\h, EventType, \Canvas\Mouse\X, \Canvas\Mouse\Y)
    EndWith
    
    If *This And (Not *This\Scroll\v\at And Not *This\Scroll\h\at)
      If ListSize(*This\items())
        With *This
          If Not \Hide And Not \Disable And \Interact
            CompilerIf #PB_Compiler_OS = #PB_OS_MacOS 
              Control = Bool(*This\Canvas\Key[1] & #PB_Canvas_Command)
            CompilerElse
              Control = Bool(*This\Canvas\Key[1] & #PB_Canvas_Control)
            CompilerEndIf
            
            Select EventType 
              Case #PB_EventType_LeftClick : PostEvent(#PB_Event_Widget, \Canvas\Window, \Canvas\Gadget, #PB_EventType_LeftClick)
              Case #PB_EventType_RightClick : PostEvent(#PB_Event_Widget, \Canvas\Window, \Canvas\Gadget, #PB_EventType_RightClick)
              Case #PB_EventType_LeftDoubleClick : PostEvent(#PB_Event_Widget, \Canvas\Window, \Canvas\Gadget, #PB_EventType_LeftDoubleClick)
                
              Case #PB_EventType_MouseLeave
                \index[1] =- 1
                Repaint = 1
                
              Case #PB_EventType_LeftButtonDown
                PushListPosition(\items()) 
                ForEach \items()
                  If \index[1] = \items()\index 
                    \Index[2] = \index[1]
                    
                    If \Flag\ClickSelect
                      \items()\Color\State ! 2
                    Else
                      ; \items()\index[1] = \items()\index
                      \items()\Color\State = 2
                    EndIf
                    
                    ; \items()\Focus = \items()\index 
                  ElseIf ((Not \Flag\ClickSelect And \items()\Focus = \items()\index) Or \Flag\MultiSelect) And Not Control
                    \items()\index[1] =- 1
                    \items()\Color\State = 1
                    \items()\Focus =- 1
                  EndIf
                Next
                PopListPosition(\items()) 
                Repaint = 1
                
              Case #PB_EventType_LeftButtonUp
                PushListPosition(\items()) 
                ForEach \items()
                  If \index[1] = \items()\index 
                    \items()\Focus = \items()\index 
                  Else
                    If (Not \Flag\MultiSelect And Not \Flag\ClickSelect)
                      \items()\Color\State = 1
                    EndIf
                  EndIf
                Next
                PopListPosition(\items()) 
                Repaint = 1
                
              Case #PB_EventType_MouseMove  
                If \Canvas\Mouse\Y < \Y Or \Canvas\Mouse\X > Scroll::X(\Scroll\v)
                  Item.i =- 1
                ElseIf \Text\Height
                  Item.i = ((\Canvas\Mouse\Y-\Y-\Text\Y-\Scroll\Y) / \Text\Height)
                EndIf
                
                If \index[1] <> Item And Item =< ListSize(\items())
                  If isItem(\index[1], \items()) 
                    If \index[1] <> ListIndex(\items())
                      SelectElement(\items(), \index[1]) 
                    EndIf
                    
                    If \Canvas\Mouse\buttons & #PB_Canvas_LeftButton 
                      If (\Flag\MultiSelect And Not Control)
                        \items()\Color\State = 2
                      ElseIf Not \Flag\ClickSelect
                        \items()\Color\State = 1
                      EndIf
                    EndIf
                  EndIf
                  
                  If \Canvas\Mouse\buttons & #PB_Canvas_LeftButton And itemSelect(Item, \items())
                    If (Not \Flag\MultiSelect And Not \Flag\ClickSelect)
                      \items()\Color\State = 2
                    ElseIf Not \Flag\ClickSelect And (\Flag\MultiSelect And Not Control)
                      \items()\index[1] = \items()\index
                      \items()\Color\State = 2
                    EndIf
                  EndIf
                  
                  \index[1] = Item
                  Repaint = #True
                  
                  If \Canvas\Mouse\buttons & #PB_Canvas_LeftButton
                    If (\Flag\MultiSelect And Not Control)
                      PushListPosition(\items()) 
                      ForEach \items()
                        If  Not \items()\Hide
                          If ((\Index[2] =< \index[1] And \Index[2] =< \items()\index And \index[1] >= \items()\index) Or
                              (\Index[2] >= \index[1] And \Index[2] >= \items()\index And \index[1] =< \items()\index)) 
                            If \items()\index[1] <> \items()\index
                              \items()\index[1] = \items()\index
                              \items()\Color\State = 2
                            EndIf
                          Else
                            \items()\index[1] =- 1
                            \items()\Color\State = 1
                            \items()\Focus =- 1
                          EndIf
                        EndIf
                      Next
                      PopListPosition(\items()) 
                    EndIf
                    
                    ; ; ;                   If \Index[2] =< \index[1]
                    ; ; ;                     PushListPosition(\items()) 
                    ; ; ;                     While PreviousElement(\items()) And \Index[2] < \items()\index And Not \items()\Hide
                    ; ; ;                       If \items()\index[1] <> \items()\index
                    ; ; ;                         \items()\index[1] = \items()\index
                    ; ; ;                         \items()\Color\State = 2
                    ; ; ;                       EndIf
                    ; ; ;                     Wend
                    ; ; ;                     PopListPosition(\items()) 
                    ; ; ;                     PushListPosition(\items()) 
                    ; ; ;                     While NextElement(\items()) And \items()\index[1] = \items()\index And Not \items()\Hide
                    ; ; ;                       \items()\index[1] =- 1
                    ; ; ;                       \items()\Color\State = 1
                    ; ; ;                       \items()\Focus =- 1
                    ; ; ;                     Wend
                    ; ; ;                     PopListPosition(\items()) 
                    ; ; ;                     PushListPosition(\items()) 
                    ; ; ;                     If \Index[2] = \index[1] And PreviousElement(\items()) And \items()\index[1] = \items()\index And Not \items()\Hide
                    ; ; ;                       \items()\index[1] =- 1
                    ; ; ;                       \items()\Color\State = 1
                    ; ; ;                       \items()\Focus =- 1
                    ; ; ;                     EndIf
                    ; ; ;                     PopListPosition(\items()) 
                    ; ; ;                   ElseIf \Index[2] > \index[1]
                    ; ; ;                     PushListPosition(\items()) 
                    ; ; ;                     While NextElement(\items()) And \Index[2] > \items()\index And Not \items()\Hide
                    ; ; ;                       If \items()\index[1] <> \items()\index
                    ; ; ;                         \items()\index[1] = \items()\index
                    ; ; ;                         \items()\Color\State = 2
                    ; ; ;                       EndIf
                    ; ; ;                     Wend
                    ; ; ;                     PopListPosition(\items()) 
                    ; ; ;                     PushListPosition(\items()) 
                    ; ; ;                     While PreviousElement(\items()) And \items()\index[1] = \items()\index And Not \items()\Hide
                    ; ; ;                       \items()\index[1] =- 1
                    ; ; ;                       \items()\Color\State = 1
                    ; ; ;                       \items()\Focus =- 1
                    ; ; ;                     Wend
                    ; ; ;                     PopListPosition(\items()) 
                    ; ; ;                   EndIf
                  EndIf
                EndIf
                
              Default
                itemSelect(\Index[2], \items())
            EndSelect
          EndIf
        EndWith    
        
        With *This\items()
          If *Focus = *This
            CompilerIf #PB_Compiler_OS = #PB_OS_MacOS 
              Control = Bool(*This\Canvas\Key[1] & #PB_Canvas_Command)
            CompilerElse
              Control = Bool(*This\Canvas\Key[1] & #PB_Canvas_Control)
            CompilerEndIf
            
            Select EventType
              Case #PB_EventType_KeyUp
              Case #PB_EventType_KeyDown
                Select *This\Canvas\Key
                  Case #PB_Shortcut_V
                EndSelect 
                
            EndSelect
          EndIf
          
          
        EndWith
      EndIf
    Else
      *This\index[1] =- 1
    EndIf
    
    ProcedureReturn Repaint
  EndProcedure
  
  Procedure.i CallBack(*This.Widget_S, EventType.i, Canvas.i=-1, CanvasModifiers.i=-1)
    ProcedureReturn Text::CallBack(@Events(), *This, EventType, Canvas, CanvasModifiers)
  EndProcedure
  
  Procedure.i Widget(*This.Widget_S, Canvas.i, X.i, Y.i, Width.i, Height.i, Text.s, Flag.i=0, Radius.i=0)
    Protected Window.i
    
    CompilerSelect #PB_Compiler_OS
      CompilerCase #PB_OS_MacOS
        Protected *g.sdkGadget = IsGadget(Canvas) : Window = *g\Window
      CompilerCase #PB_OS_Linux
;         GadgetWindowID = gtk_widget_get_toplevel_ (GadgetID(Canvas))
      CompilerCase #PB_OS_Windows
        Window = GetProp_(GetAncestor_(GadgetID(Canvas), #GA_ROOT), "PB_WindowID") - 1
    CompilerEndSelect
    
    If *This
      With *This
        \Type = #PB_GadgetType_ListView
        \Cursor = #PB_Cursor_Default
        \Canvas\Gadget = Canvas
        If Not \Canvas\Window
          \Canvas\Window = GetGadgetData(Canvas)
        EndIf
        \Radius = Radius
        \Interact = 1
        \Caret[1] =- 1
        \index[1] =- 1
        \X =- 1
        \Y =- 1
        
        ; Set the Default widget flag
        If Bool(Flag&#PB_Text_WordWrap)
          Flag&~#PB_Text_MultiLine
        EndIf
        
        If Bool(Flag&#PB_Text_MultiLine)
          Flag&~#PB_Text_WordWrap
        EndIf
        
        If Not \Text\FontID
          \Text\FontID = GetGadgetFont(#PB_Default) ; Bug in Mac os
        EndIf
        
        \fSize = Bool(Not Flag&#PB_Flag_BorderLess)+1
        \bSize = \fSize
        
          \Flag\MultiSelect = Bool(flag&#PB_Flag_MultiSelect)
          \Flag\ClickSelect = Bool(flag&#PB_Flag_ClickSelect)
          \flag\buttons = Bool(flag&#PB_Flag_NoButtons)
          \Flag\lines = Bool(flag&#PB_Flag_NoLines)
          \Flag\FullSelection = Bool(flag&#PB_Flag_FullSelection)
          \Flag\AlwaysSelection = Bool(flag&#PB_Flag_AlwaysSelection)
          \Flag\CheckBoxes = Bool(flag&#PB_Flag_CheckBoxes)
          \Flag\GridLines = Bool(flag&#PB_Flag_GridLines)
          
          \Text\Vertical = Bool(Flag&#PB_Flag_Vertical)
          \Text\Editable = Bool(Not Flag&#PB_Text_ReadOnly)
          
          If Bool(Flag&#PB_Text_WordWrap)
            \Text\MultiLine = 1
          ElseIf Bool(Flag&#PB_Text_MultiLine)
            \Text\MultiLine = 2
          Else
            \Text\MultiLine =- 1
          EndIf
          
          \Text\Numeric = Bool(Flag&#PB_Text_Numeric)
          \Text\Lower = Bool(Flag&#PB_Text_LowerCase)
          \Text\Upper = Bool(Flag&#PB_Text_UpperCase)
          \Text\Pass = Bool(Flag&#PB_Text_Password)
          
          \Text\Align\Horizontal = Bool(Flag&#PB_Text_Center)
          \Text\Align\Vertical = Bool(Flag&#PB_Text_Middle)
          \Text\Align\Right = Bool(Flag&#PB_Text_Right)
          \Text\Align\Bottom = Bool(Flag&#PB_Text_Bottom)
          
          CompilerIf #PB_Compiler_OS = #PB_OS_MacOS 
            If \Text\Vertical
              \Text\X = \fSize 
              \Text\y = \fSize+5
            Else
              \Text\X = \fSize+5
              \Text\y = \fSize
            EndIf
          CompilerElseIf #PB_Compiler_OS = #PB_OS_Windows
            If \Text\Vertical
              \Text\X = \fSize 
              \Text\y = \fSize+1
            Else
              \Text\X = \fSize+1
              \Text\y = \fSize
            EndIf
          CompilerElseIf #PB_Compiler_OS = #PB_OS_Linux
            If \Text\Vertical
              \Text\X = \fSize 
              \Text\y = \fSize+6
            Else
              \Text\X = \fSize+6
              \Text\y = \fSize
            EndIf
          CompilerEndIf 
          
          \Text\Change = 1
          \Color = Colors
          \color\Alpha = 255
          \Color\Fore[0] = 0
          
          \Row\color\alpha = 255
        \Row\Color = Colors
        \Row\color\alpha = 255
        \Row\color\alpha[1] = 0
        \Row\Color\Fore[0] = 0
        \Row\Color\Fore[1] = 0
        \Row\Color\Fore[2] = 0
        
        \Row\Color\Frame[2] = \Row\Color\Back[2]
        
          If \Text\Editable
            \Text\Editable = 0
            \Color\Back[0] = $FFFFFFFF 
          Else
            \Color\Back[0] = $FFF0F0F0  
          EndIf
          
        EndIf
        
        ; Create scrollbar
        Scroll::Bars(\Scroll, 16, 7, 0)
    
        Resize(*This, X,Y,Width,Height)
      EndWith
      
    ProcedureReturn *This
  EndProcedure
  
  Procedure.i Create(Canvas.i, Widget, X.i, Y.i, Width.i, Height.i, Text.s, Flag.i=0, Radius.i=0)
    Protected *Widget, *This.Widget_S = AllocateStructure(Widget_S)
    
    If *This
      add_widget(Widget, *Widget)
      
      *This\Index = Widget
      *This\Handle = *Widget
      List()\Widget = *This
      
      Widget(*This, Canvas, x, y, Width, Height, Text.s, Flag, Radius)
      PostEvent(#PB_Event_Widget, *This\Canvas\Window, *This, #PB_EventType_Create)
      PostEvent(#PB_Event_Gadget, *This\Canvas\Window, *This\Canvas\Gadget, #PB_EventType_Repaint)
    EndIf
    
    ProcedureReturn *This
  EndProcedure
  
  Procedure Canvas_CallBack()
    Protected Repaint, *This.Widget_S = GetGadgetData(EventGadget())
    
    With *This
      Select EventType()
        Case #PB_EventType_Repaint : Repaint = 1
        Case #PB_EventType_Resize : ResizeGadget(\Canvas\Gadget, #PB_Ignore, #PB_Ignore, #PB_Ignore, #PB_Ignore) ; Bug (562)
          Repaint | Resize(*This, #PB_Ignore, #PB_Ignore, GadgetWidth(\Canvas\Gadget), GadgetHeight(\Canvas\Gadget))
      EndSelect
      
      Repaint | CallBack(*This, EventType())
      
      If Repaint 
        Text::ReDraw(*This)
      EndIf
      
    EndWith
  EndProcedure
  
  Procedure.i Gadget(Gadget.i, X.i, Y.i, Width.i, Height.i, Flag.i=0)
    Protected *This.Widget_S = AllocateStructure(Widget_S)
    Protected g = CanvasGadget(Gadget, X, Y, Width, Height, #PB_Canvas_Keyboard) : If Gadget=-1 : Gadget=g : EndIf
    
    If *This
      With *This
        Widget(*This, Gadget, 0, 0, Width, Height, "", Flag)
        
        SetGadgetData(Gadget, *This)
        BindGadgetEvent(Gadget, @Canvas_CallBack())
      EndWith
    EndIf
    
    ProcedureReturn g
  EndProcedure
  
EndModule

;- EXAMPLE
CompilerIf #PB_Compiler_IsMainFile
  Define a,i
  Define g, Text.s
  ; Define m.s=#CRLF$
  Define m.s;=#LF$
  
  Text.s = "This is a long line" + m.s +
           "Who should show," + m.s +
           "I have to write the text in the box or not." + m.s +
           "The string must be very long" + m.s +
           "Otherwise it will not work."
  
  Procedure ResizeCallBack()
    ;ResizeGadget(100, WindowWidth(EventWindow(), #PB_Window_InnerCoordinate)-62, WindowHeight(EventWindow(), #PB_Window_InnerCoordinate)-30, #PB_Ignore, #PB_Ignore)
    ResizeGadget(10, #PB_Ignore, #PB_Ignore, WindowWidth(EventWindow(), #PB_Window_InnerCoordinate)-65, WindowHeight(EventWindow(), #PB_Window_InnerCoordinate)-16)
    CompilerIf #PB_Compiler_Version =< 546
      PostEvent(#PB_Event_Gadget, EventWindow(), 16, #PB_EventType_Resize)
    CompilerEndIf
  EndProcedure
  
  Procedure SplitterCallBack()
    PostEvent(#PB_Event_Gadget, EventWindow(), 16, #PB_EventType_Resize)
  EndProcedure
  
  CompilerIf #PB_Compiler_OS = #PB_OS_MacOS 
    LoadFont(0, "Arial", 16)
  CompilerElse
    LoadFont(0, "Arial", 12)
  CompilerEndIf 
  
  If OpenWindow(30, 0, 0, 422, 491, "ListViewGadget", #PB_Window_SystemMenu | #PB_Window_SizeGadget | #PB_Window_ScreenCentered)
    ;ButtonGadget(100, 490-60,490-30,67,25,"~wrap")
    
    ListViewGadget(0, 8, 8, 306, 233) ;: SetGadgetText(0, Text.s) 
    For a = 0 To 2
      AddGadgetItem(0, a, "Line "+Str(a)+ " of the Listview")
    Next
    AddGadgetItem(0, a, Text)
    For a = 4 To 16
      AddGadgetItem(0, a, "Line "+Str(a)+ " of the Listview")
    Next
    SetGadgetFont(0, FontID(0))
    
    
    g=16
    ListView::Gadget(g, 8, 133+5+8, 306, 233, #PB_Flag_GridLines) ;: ListView::SetText(g, Text.s) 
    
    *w=GetGadgetData(g)
    
    For a = 0 To 2
      ListView::AddItem(*w, a, "Line "+Str(a)+ " of the Listview")
    Next
    ListView::AddItem(*w, a, Text)
    For a = 4 To 16
      ListView::AddItem(*w, a, "Line "+Str(a)+ " of the Listview")
    Next
    ListView::SetFont(*w, FontID(0))
    
    SplitterGadget(10,8, 8, 306, 491-16, 0,g)
    CompilerIf #PB_Compiler_Version =< 546
      BindGadgetEvent(10, @SplitterCallBack())
    CompilerEndIf
    BindEvent(#PB_Event_SizeWindow, @ResizeCallBack(), 0)
    
    ; Debug "высота "+GadgetHeight(0) +" "+ GadgetHeight(g)
    Repeat 
      Define Event = WaitWindowEvent()
      
      Select Event
        Case #PB_Event_Gadget
          If EventGadget() = 100
            Select EventType()
              Case #PB_EventType_LeftClick
                Define *E.Widget_S = GetGadgetData(g)
                
            EndSelect
          EndIf
          
        Case #PB_Event_LeftClick  
          SetActiveGadget(0)
        Case #PB_Event_RightClick 
          SetActiveGadget(10)
      EndSelect
    Until Event = #PB_Event_CloseWindow
  EndIf
CompilerEndIf
; IDE Options = PureBasic 5.62 (MacOS X - x64)
; Folding = -------------------0f-f----------------------------
; EnableXP
; IDE Options = PureBasic 5.62 (MacOS X - x64)
; Folding = r--b+--BHgnnD-
; EnableXP