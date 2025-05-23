Attribute VB_Name = "Optim"
Option Explicit
Option Base 1

' Paramètres d'itération constants
Public maxTime As Double    ' Temps de calcul maximum
Public nValGlo As Integer   ' Nombre de valeurs explorées lors de la recherche globale
Public nValLoc As Integer   ' Nombre de valeurs explorées lors de la recherche locale
Public nValConf As Integer  ' Nombre de confirmations pour calcul robuste
Public memSize As Integer    ' Taille de la pile de mémoire (memStack)
Public coefR2(1 To 6) As Double ' Coefficients des dates-clé pour le R² global
Public maxSpaceSize As Long ' Taille maximale de l'espace des paramètres

' Constantes liées à l'interface XL
Private Const colParVal As Integer = 2
Private Const rowParVal As Integer = 21

' Liste et codage des paramètres du modèle
Private parList(1 To 7) As Boolean    ' Liste des paramètres ajustables : JED, Tc, Ec, Cx, JLD, Tf, Ef
Private nPar As Integer         ' Nombre de paramètres (ajustables)
Private nParVal() As Integer    ' [nPar] Nombre de valeurs discrètes (codage) des paramètres
Private parValue() As Variant   ' [nPar[nParVal]] Tableau du codages des paramètres

' Variables de l'ajustement
Private curPoint As Variant     ' Int[nPar] Position courrante du point
Private bestPoint As Variant    ' Int[nPar] Position du meilleur point
Private bestR2 As Double    ' Valeur du R2 du meilleur point
Private bestIter As Long    ' Numéro de l'itération du meilleur R²

' Mémorisation des évaluations
Private spaceSize As Long
Private fctSpace As EvalSpace
Private memStack As RankedStack
Private evalCnt As Long         ' Décompte des évaluations

'''''''''''''''''''''''
' Procédures publiques
'''''''''''''''''''''''

Public Sub SetParList(pJED As Boolean, pTc As Boolean, pEc As Boolean, _
                      pCx As Boolean, pJLD As Boolean, _
                      pTf As Boolean, pEf As Boolean)
'   Définit la liste des paramètres ajustables
    Dim cp() As Integer
    Dim bp() As Integer
    Dim np As Integer
    parList(1) = pJED: If pJED Then np = np + 1
    parList(2) = pTc: If pTc Then np = np + 1
    parList(3) = pEc: If pEc Then np = np + 1
    parList(4) = pCx: If pCx Then np = np + 1
    parList(5) = pJLD: If pJLD Then np = np + 1
    parList(6) = pTf: If pTf Then np = np + 1
    parList(7) = pEf: If pEf Then np = np + 1
    nPar = np
    ReDim cp(1 To np)
    ReDim bp(1 To np)
    curPoint = cp
    bestPoint = bp
End Sub
Public Sub ReadIterPara()
'   Lecture des paramètres d'itération
    Dim k As Integer
'   Coefficient du R² global (pour ajuster les Fx)
    For k = 1 To 6
        coefR2(k) = Sheets("Model").Cells(firstDateRow - 2, firstObsCol + k - 1).value
    Next
'   Autres paramètres d'itération
    With Sheets("Ajust")
        memSize = .Cells(2, 2).value
        nValConf = .Cells(3, 2).value
        nValGlo = .Cells(4, 2).value
        nValLoc = .Cells(5, 2).value
        maxTime = .Cells(6, 2).value
        maxSpaceSize = .Cells(7, 2).value
    End With
End Sub
Public Sub AjustModel()
    Dim n As Integer
    Dim k As Integer
    Dim i As Long
    Dim t0 As Double
    Dim com As String
    Dim tpsMax As Boolean
    Dim tailleMax As Long
    Dim R2 As Double
    Dim exces As Double
    tailleMax = IniAjust
    If tailleMax = 0 Then
        ' Echantillon initial aléatoire
        Sheets("Dbg").Range("A2:AZ60000").ClearContents
        n = nPar + Math.Log(spaceSize)
        t0 = Timer
        For i = 1 To nPar * n
            SetRnd curPoint
            EvalModel curPoint
If DBG2 Then
    Sheets("Dbg").Cells(1 + evalCnt, 3).value = "INI"
End If
        Next
        ' Algorythme principal
        Do While SetToBest(curPoint) _
             And Timer - t0 < maxTime _
             And evalCnt < spaceSize
If DBG2 Then
    Cells.Select
    Cells(1, 1).Select
End If
            k = RndSearch(n)
            If k >= n Then  ' Pas d'amélioration locale => nouvel échantillon aléatoire
                i = 0
                Do
                    i = i + 1
                    SetRnd curPoint
If DBG2 Then
    Sheets("Dbg").Cells(1 + evalCnt + 1, 3).value = "RND"
End If
                Loop Until i = n Or EvalModel(curPoint) = bestR2
                n = n + 1
            End If
            If n > 1 And (evalCnt - bestIter / n) > 25 Then n = n - 1
        Loop
        
        ' Fin...
        If Timer - t0 > maxTime Then tpsMax = True
        EvalModel bestPoint
        Application.StatusBar = False
If DBG1 Then
    With Sheets("Dbg")
    For k = 1 To memStack.stackSize
        .Cells(1 + k, 1).value = k
        .Cells(1 + k, 2).value = memStack.GetFct(k)
        .Cells(1 + k, 3).value = fctSpace.IsClosed(memStack.GetPos(k))
        For n = 1 To nPar
            i = memStack.GetPos(k)(n)
            .Cells(1 + k, 3 + n).value = parValue(n)(i)
        Next
    Next
    End With
End If
    End If
    If parList(1) Then com = com & "JED  "
    If parList(2) Then com = com & "Tc  "
    If parList(3) Then com = com & "Ec  "
    If parList(4) Then com = com & "C*  "
    If parList(5) Then com = com & "JLD  "
    If parList(6) Then com = com & "Tf  "
    If parList(7) Then com = com & "Ef  "
    If com <> "" Then com = "Ajust : " & com
    If tpsMax Then com = com & "Temps maximal atteint !  "
    exces = tailleMax / maxSpaceSize
    If tailleMax > 0 Then com = com & "Taille de l'espace excessive de " & Format((exces - 1) * 100, "0") & "%"
    Range("Comments").value = com
    Application.StatusBar = False
End Sub


'''''''''''''''''''''''
' Procédures internes
'''''''''''''''''''''''

' Initialisation '
''''''''''''''''''
Private Function IniAjust() As Long
    Dim i As Integer
    Dim n As Integer
    Randomize
    ReDim parValue(nPar)
    ReDim nParVal(nPar)
    bestR2 = -1E+24
    evalCnt = 0
    n = 0: spaceSize = 1
    For i = 1 To 7  ' Lecture de l'échelle de valeur des paramètres
        If parList(i) Then
            n = n + 1
            ReadPar n, colParVal + i - 1
            spaceSize = spaceSize * nParVal(n)
        End If
    Next
    Set memStack = New RankedStack
    memSize = memSize * nPar
    If memSize >= spaceSize - 1 Then memSize = spaceSize - 1
    memStack.Init memSize
    Set fctSpace = New EvalSpace
    IniAjust = fctSpace.Init(nPar, nParVal)
End Function
Private Function ReadPar(n As Integer, col As Integer) As Double
'   Echelonnage des valeurs des paramètres ajustables
    Dim rw As Integer
    Dim i As Integer
    Dim vals() As Double
    ReDim vals(1 To 100)
    With Sheets("Ajust")
    rw = rowParVal
    Do Until .Cells(rw, col).value <> "" Or rw = 100 + rowParVal
        rw = rw + 1  ' Passer les cellules vides
    Loop
    Do Until .Cells(rw, col).value = "" Or rw = 100 + rowParVal
        i = i + 1 ' Compter et lire les cellules pleines
        vals(i) = .Cells(rw, col).value
        rw = rw + 1
    Loop
    ReDim Preserve vals(1 To i)
    End With
    nParVal(n) = i
    parValue(n) = vals
End Function

' Sous-procédures de l'ajustement
''''''''''''''''''''''''''''''''''
Private Function SetToBest(ByRef pp As Variant) As Boolean
' Place CurPoint au meilleur point non fermé de la pile de mémoire
    Dim i As Integer
    Dim k As Integer
    Do: i = i + 1
    Loop While i < memSize And fctSpace.IsClosed(memStack.GetPos(i))
    If i < memSize Then
        For k = 1 To nPar
            pp(k) = memStack.GetPos(i)(k)
        Next
        SetToBest = True
    Else
        SetToBest = False
    End If
End Function
Private Sub SetRnd(ByRef pp As Variant)
' Impose au point pp des coordonnées aléatoire
    Dim k As Integer
    For k = 1 To nPar
        pp(k) = 1 + Int(Rnd * (nParVal(k)))
    Next
End Sub
Private Function RndSearch(cntMax As Integer) As Integer
' Ferme le point courrant, puis cherche cntMax nouveaux points dans le voisinage
    Dim span() As Integer
    Dim test() As Double
    Dim pk As Integer
    Dim k As Integer
    Dim cnt As Integer
    Dim R2 As Double
    Dim R2ini As Double
    Dim fail As Integer
    ReDim span(nPar)
    ReDim test(nPar)
    For k = 1 To nPar
        span(k) = 1
        test(k) = curPoint(k)
    Next
    ' Fermer le point
    For k = 1 To nPar
        If test(k) > 1 Then
            test(k) = test(k) - 1
            If Not fctSpace.IsDone(test) Then
                R2 = EvalModel(test)
If DBG2 Then
    Sheets("Dbg").Cells(1 + evalCnt, 3).value = "CLO"
End If
            End If
            test(k) = test(k) + 1
        End If
        If test(k) < nParVal(k) Then
            test(k) = test(k) + 1
            If Not fctSpace.IsDone(test) Then
                R2 = EvalModel(test)
If DBG2 Then
    Sheets("Dbg").Cells(1 + evalCnt, 3).value = "CLO"
End If
            End If
            test(k) = test(k) - 1
        End If
    Next
    ' Tirer un échantillon aléatoire à variance croissante, jusqu'à amélioration
    R2ini = fctSpace.GetVal(curPoint)
    Do
        For k = 1 To nPar ' Chercher un nouveau point valide dans le span
            Do: pk = Int(curPoint(k) + (Rnd - 0.5) * 2 * span(k))
            Loop Until pk >= 1 And pk <= nParVal(k)
            test(k) = pk
        Next
        If fctSpace.IsDone(test) Then
            fail = fail + 1
        Else    ' Evaluer le point
            R2 = EvalModel(test)
If DBG2 Then
    Sheets("Dbg").Cells(1 + evalCnt, 3).value = "LOC"
End If
            cnt = cnt + 1
        End If
        If fail > nPar Then
            fail = 0
            For k = 1 To nPar
                If span(k) < nParVal(k) Then span(k) = span(k) + 1
            Next
        End If
    Loop Until R2 > R2ini Or cnt >= cntMax Or evalCnt >= spaceSize
    RndSearch = cnt
End Function

' Evaluation du R² '
''''''''''''''''''''
Private Function EvalModel(ByRef pp As Variant) As Double
'   Evaluation du R² avec mémorisation
    Dim pJED As Variant
    Dim pTc As Variant
    Dim pEc As Variant
    Dim pCx As Variant
    Dim pJLD As Variant
    Dim pTf As Variant
    Dim pEf As Variant
    Dim k As Integer
    Dim R2 As Double
    Dim col As Integer
    Dim infoStr As String
    Dim x As Double
    ' Détermination des paramètres ajustés
    If parList(1) Then
        k = k + 1: pJED = parValue(k)(pp(k))
    End If
    If parList(2) Then
        k = k + 1: pTc = parValue(k)(pp(k))
    End If
    If parList(3) Then
        k = k + 1: pEc = parValue(k)(pp(k))
    End If
    If parList(4) Then
        k = k + 1: pCx = parValue(k)(pp(k))
    End If
    If parList(5) Then
        k = k + 1: pJLD = parValue(k)(pp(k))
    End If
    If parList(6) Then
        k = k + 1: pTf = parValue(k)(pp(k))
    End If
    If parList(7) Then
        k = k + 1: pEf = parValue(k)(pp(k))
    End If
    ' Evaluation de R²
    SetPara paraJED:=pJED, paraTc:=pTc, paraEc:=pEc, paraCx:=pCx, _
            paraJLD:=pJLD, paraTf:=pTf, paraEf:=pEf
    R2 = ComputeModel
    ' Mise à jour du meilleur
    If R2 >= bestR2 Then
        bestR2 = R2
        bestIter = evalCnt + 1
        For k = 1 To nPar
            bestPoint(k) = pp(k)
        Next
    End If
    ' Mise à jour de la mémoire
    evalCnt = evalCnt + 1
    fctSpace.SetVal pp, R2
    memStack.Push pp, R2
    ' Affichage des informations
    infoStr = "Opt[" & Format(bestIter, "0000") & "] "
    For k = 1 To nPar
        infoStr = infoStr & Format(parValue(k)(bestPoint(k)), "00.00") & " | "
    Next
    infoStr = infoStr & " R² = " & Format(bestR2, "0.000")
    infoStr = infoStr & "  >>  Act[" & Format(evalCnt, "0000") & "] "
    col = 2
    For k = 1 To nPar
        x = parValue(k)(pp(k))
        infoStr = infoStr & Format(x, "00.00") & " | "
        col = col + 1
    Next
    col = col + nPar
    infoStr = infoStr & " R² = " & Format(R2, "0.000")
    Application.StatusBar = infoStr
' Ecriture sur la feuille de controle
If DBG2 Then
    With Sheets("Dbg")
    .Cells(1 + evalCnt, 1).value = evalCnt
    .Cells(1 + evalCnt, 2).value = R2
    For k = 1 To nPar
        .Cells(1 + evalCnt, 3 + k).value = parValue(k)(pp(k))
    Next
    End With
End If
    EvalModel = R2
End Function
