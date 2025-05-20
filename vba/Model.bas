Attribute VB_Name = "Model"
Option Explicit


Public Const DBG0 As Boolean = False
Public Const DBG1 As Boolean = False
Public Const DBG2 As Boolean = False

' VARIABLES GLOBALES
''''''''''''''''''''
Public Const nDays As Integer = 504 ' Nombre de jours dans une année
'   (depuis le 15/08 d'avant)
Public Const dayOffset As Integer = nDays - 365
'   Les jours sont numérotés de -138 à +365 dans l'interface XL
'   et de +1 à +504 dans les modules VBA (=XL+dayOffset=139)
Public nYear As Integer ' Nombre d'années d'observation

' VARIABLES DU MODULE
'''''''''''''''''''''
'   Paramètres de Chilling
Private chilOpt As Boolean  ' Option de vernalisation
Private TmpC As Integer  ' Température utile (1=min, 2=moy, 3=max)
Private MdlC As Integer  ' N° de modèle
Private JED As Integer   ' Jour d'entrée en dormance
Private TC As Double     ' Température caractéristique (1er paramètre du Rc)
Private Ec As Double     ' Etendue thermique (2eme paramètre du Rc)
Private Cx As Double     ' Seuil de levée de dormance
'   Paramètres de Forcing
Private TmpF As Integer  ' Température utile (1=min, 2=moy, 3=max)
Private MdlF As Integer  ' N° de modèle
Private JLD As Integer   ' Jour de levée de dormance
Private Tf As Double     ' Température caractéristique (1er paramètre du Rf)
Private Ef As Double     ' Etendue thermique (2eme paramètre du Rf)
'   Données d'entrée
Private tabChilT() As Double    ' [nDays * nYear]  température utile pour le chilling
Private tabForcT() As Double    ' [nDays * nYear]  température utile pour le forcing
Public tabDFobs() As Double    ' [6 * nYear]    dates de floraison observées
Private tabDFmax(1 To 6) As Double    ' [6 * nYear]    dates de floraison mmaximales
Private tabVarObs(1 To 6) As Double   ' variances totlaes observées des dates de floraison
'   Paramètres phénologiques
Private tabJLD() As Integer  ' [nYear]  Jour de levée de dormance (début du forcing)
Public tabSf() As Double    ' [nDays * nYear]  "state fo forcing" (cumul de chaleur)
'   Paramètres de sortie
Private tabDFpre() As Double    ' [6 * nYear]    dates de floraison prévues
Private tabVarRes(1 To 6) As Double   ' Variances résiduelles
Private tabFx(1 To 6) As Double ' Seuil de débourrement

'''''''''''''''''''''''''
' INTERFACE : BOUTONS XL
'''''''''''''''''''''''''
Public Sub CMDcalculer()
' Calcule les prévisions à partir des paramètres courrants en optimisant les F*
InterfaceOption
    Range("Comments").value = ""
    ReadData
    ComputeModel (Sheets("Model").Range("OptAjustF").value)
    WriteResults
    Sheets("Sf").Range("B2:BW1000").ClearContents
    If Sheets("Model").Range("OptWriteSf").value = True Then WriteSf
End Sub
Public Sub CMDoptimiser()
' Calcule les prévisions à partir des paramètres courrants en optimisant les F*
InterfaceOption
    Range("Comments").value = ""
    ReadData
    AjustForm.Show
    WritePara
    WriteResults
End Sub

Public Sub OPTchilling()
InterfaceOption
    With Sheets("Model")
        If .Range("ChilOpt").value Then
            .Range("A17:A22").Font.ColorIndex = 1
            .Range("C17:C22").Font.ColorIndex = 1
            .Range("B18:B21").Font.ColorIndex = 7
            .Range("B17").Font.ColorIndex = 5
            .Range("D18").Font.ColorIndex = 5
            Sheets("Prev").Range("K4:K9").Font.ColorIndex = 1
            Sheets("Prev").Range("L4:L9").Font.ColorIndex = 5
            chilOpt = True
        Else
            .Range("A17:D22").Font.ColorIndex = 15
            Sheets("Prev").Range("K4:L9").Font.ColorIndex = 15
            chilOpt = False
        End If
    End With
End Sub
''''''''''''''''''''''
' RESULTATS "PUBLICS"
''''''''''''''''''''''

Public Sub SetPara(Optional paraTmpC As Variant = False, _
                   Optional paraMdlC As Variant = False, _
                   Optional paraJED As Variant = False, _
                   Optional paraTc As Variant = False, _
                   Optional paraEc As Variant = False, _
                   Optional paraCx As Variant = False, _
                   Optional paraTmpF As Variant = False, _
                   Optional paraMdlF As Variant = False, _
                   Optional paraJLD As Variant = False, _
                   Optional paraTf As Variant = False, _
                   Optional paraEf As Variant = False)
' Définition (publique) de la valeur des paramètres
' + Vérification des conditions de validité des paramètres
' NB : les JED et JLD sont en convention "externe" dans les arguments et interne dans la procdure
'   ils sont fournis entre -138 et 365 (ref. 01/01) et convertis entre 1 et 504 (ref. 15/08)
     ' Chilling
    If VarType(paraTmpC) = vbInteger Then
        If paraTmpC > 0 And paraTmpC < 4 Then TmpC = paraTmpC _
        Else msgbox "Erreur dans SetPara : valeur de tmpC invalide !"
    End If
    If VarType(paraMdlC) = vbInteger Then
        If paraMdlC >= 0 And paraMdlC < 6 Then MdlC = paraMdlC _
        Else msgbox "Erreur dans SetPara : valeur de mldC invalide !"
    End If
    If IsNumType(paraJED) Then
        If paraJED + dayOffset > 0 And paraJED + dayOffset < nDays _
        Then JED = paraJED + dayOffset _
        Else msgbox "Erreur dans SetPara : valeur de JED invalide !"
    End If
    If IsNumType(paraTc) Then
        If paraTc = 0 Then
            msgbox "Valeur de Tc non valide (" & paraTc & ") !" & vbCr & _
                   "La valeur de 0.001 est utilisée à la place."
            TC = 0.001
        Else
            TC = paraTc
        End If
    End If
    If IsNumType(paraEc) Then
        If paraEc = 0 Then
            msgbox "Valeur de Ec non valide (" & paraEc & ") !" & vbCr & _
                   "La valeur de 0.001 est utilisée à la place."
            Ec = 0.001
        Else
            Ec = paraEc
        End If
    End If
    If IsNumType(paraCx) Then
        If paraCx < 0 Then
            msgbox "Valeur de Cx non valide (" & paraCx & ") !" & vbCr & _
                   "La valeur de 0 est utilisée à la place."
            Cx = 0
        Else
            Cx = paraCx
        End If
    End If
     ' Forcing
    If VarType(paraTmpF) = vbInteger Then
        If paraTmpF > 0 And paraTmpF < 4 Then TmpF = paraTmpF _
        Else msgbox "Erreur dans SetPara : valeur de tmpF invalide !"
    End If
    If VarType(paraMdlF) = vbInteger Then
        If paraMdlF >= 0 And paraMdlF < 6 Then MdlF = paraMdlF _
        Else msgbox "Erreur dans SetPara : valeur de mdlF invalide !"
    End If
    If IsNumType(paraJLD) Then
        If paraJLD + dayOffset > 0 And paraJLD + dayOffset < nDays _
        Then JLD = paraJLD + dayOffset _
        Else msgbox "Erreur dans SetPara : valeur de JLD invalide !"
    End If
    If IsNumType(paraTf) Then
        If paraTf = 0 Then
            msgbox "Valeur de Tf non valide (" & paraTf & ") !" & vbCr & _
                   "La valeur de 0.001 est utilisée à la place."
            Tf = 0.001
        Else
            Tf = paraTf
        End If
    End If
    If IsNumType(paraEf) Then
        If paraEf <= 0 Then
            msgbox "Valeur de Ef non valide (" & paraEf & ") !" & vbCr & _
                   "La valeur de 0.001 est utilisée à la place."
            Ef = 0.001
        Else
            Ef = paraEf
        End If
    End If
End Sub
Public Function ComputeModel(Optional ajFx As Boolean = True) As Double
' Calcule les prévisions à partir des paramètres courrants
' en optimisant les F*, et retourne le R² global
''''Dim t0 As Double
'''Dim t1 As Double
'''t0 = Timer
    ComputeJLD
    ComputeSf
'''t1 = Timer - t0
'''t0 = Timer
    If ajFx Then AjustFx Else ReadFx
'''msgbox "JLD + Sf : " & t1 & vbCr & "AjustF : " & Timer - t0
    ComputeModel = ComputeR2
End Function
Public Sub WriteResults()
' Ecrit les résultats : seuils F* optimaux et dates prévues (lévée de dormance et floraison)
    Dim y As Double
    Dim k As Double
    Application.Calculation = xlCalculationManual
    For y = 1 To nYear      ' Dates de levée de dormance
        Sheets("Model").Cells(firstDateRow + y - 1, firstPrevCol - 2).value _
             = tabJLD(y) - dayOffset
    Next
    For k = 1 To 6          ' Seuils F*
        Sheets("Model").Cells(firstDateRow - 2, firstPrevCol + k - 1).value = tabFx(k)
        For y = 1 To nYear  ' Dates de floraison
            Sheets("Model").Cells(firstDateRow + y - 1, firstPrevCol + k - 1).value _
                 = tabDFpre(k, y) - dayOffset
        Next
    Next
    Application.Calculation = xlCalculationAutomatic
End Sub
Public Sub WritePara()
    With Sheets("Model")
        .Range("ChilTemp").value = TmpC
        .Range("ChilMdlNb").offSet(-1, 0).value = MdlC + 1
        .Range("ChilJED").value = JED - dayOffset
        .Range("ChilTc").value = TC
        .Range("ChilEc").value = Ec
        .Range("ChilCx").value = Cx
        .Range("ForcTemp").value = TmpF
        .Range("ForcMdlNb").offSet(-1, 0).value = MdlF + 1
        .Range("ForcJLD").value = JLD - dayOffset
        .Range("ForcTf").value = Tf
        .Range("ForcEf").value = Ef
    End With
End Sub


''''''''''''''''''''
' CALCULS "PRIVES"
''''''''''''''''''''

Public Sub ReadData()
    Dim d As Long
    Dim y As Integer
    Dim k As Integer
    Dim dMoy As Double
    Dim dMax As Double
    Dim dVar As Double
' Lit les données d'entrée du modèle
    With Sheets("Model")
    nYear = .Range("ObsYearNb").value
'   Paramètres de Chilling
    chilOpt = Range("ChilOpt").value
    TmpC = .Range("ChilTemp").value
    MdlC = .Range("ChilMdlNb").value
    JED = .Range("ChilJED").value + dayOffset
    TC = .Range("ChilTc").value
    Ec = .Range("ChilEc").value
    Cx = .Range("ChilCx").value
'   Paramètres de Forcing
    TmpF = .Range("ForcTemp").value
    MdlF = .Range("ForcMdlNb").value
    JLD = .Range("ForcJLD").value + dayOffset
    Tf = .Range("ForcTf").value
    Ef = .Range("ForcEf").value
    End With
'   Températures
    ReDim tabChilT(1 To nDays, 1 To nYear)
    ReDim tabForcT(1 To nDays, 1 To nYear)
    With Sheets(TempString(TmpC))
    For y = 1 To nYear
        For d = 1 To nDays
            tabChilT(d, y) = .Cells(1 + d, 1 + y).value
        Next
    Next
    End With
    With Sheets(TempString(TmpF))
    For y = 1 To nYear
        For d = 1 To nDays
            tabForcT(d, y) = .Cells(1 + d, 1 + y).value
        Next
    Next
    End With
'   Dates de floraison
    ReDim tabDFobs(1 To 6, 1 To nYear)
    With Sheets("Model")
    For k = 1 To 6
        d = .Cells(firstDateRow, firstObsCol + k - 1).value + dayOffset
        tabDFobs(k, 1) = d
        dMax = d: dMoy = d: dVar = d * d
        For y = 2 To nYear
            d = .Cells(firstDateRow + y - 1, firstObsCol + k - 1).value + dayOffset
            tabDFobs(k, y) = d
            If d > dMax Then dMax = d
            dMoy = dMoy + d
            dVar = dVar + d * d
        Next
        tabVarObs(k) = (dVar - dMoy * dMoy / nYear)
        tabDFmax(k) = dMax
    Next
    End With
'   Redimensionnement des autres objets
    ReDim tabJLD(1 To nYear)
    ReDim tabSf(1 To nDays, 1 To nYear)
    ReDim tabDFpre(1 To 6, 1 To nYear)
    ReadIterPara
End Sub
Private Sub ComputeJLD()
' Calcule les dates de levée de dormance
    Dim y As Integer
    Dim Rc As Double
    Dim Sc As Double
    Dim j As Double
    If Not chilOpt Then    ' Date de levée de dormance fixée arbitraire
        For y = 1 To nYear
            tabJLD(y) = JLD
        Next
    Else    ' Vernalisation
        For y = 1 To nYear
            Sc = 0: j = JED
            Do Until Sc >= Cx Or j = nDays
                Sc = Sc + RcMdl(tabChilT(j, y), MdlC, TC, Ec)
                j = j + 1
            Loop
            tabJLD(y) = j
        Next
    End If
End Sub
Private Sub ComputeSf()
' Calcule les cumuls de chaleur
    Dim jMax As Integer ' Jour de fin du calcul de Sf (au delà des dates de floraison observées)
    Dim y As Integer
    Dim j As Integer
    jMax = tabDFmax(6) + 10
    If jMax > nDays Then jMax = nDays
    For y = 1 To nYear
        For j = 1 To tabJLD(y) - 1
            tabSf(j, y) = 0
        Next    ' j = tabJLD(y)
        tabSf(j, y) = RfMdl(tabForcT(j, y), MdlF, Tf, Ef)
        For j = tabJLD(y) + 1 To jMax
            tabSf(j, y) = tabSf(j - 1, y) + RfMdl(tabForcT(j, y), MdlF, Tf, Ef)
        Next
    Next
End Sub
Private Sub WriteSf()
    Dim i As Integer
    Dim j As Integer
    With Sheets("Sf")
    Sheets("Pollen").Rows(1).Copy .Rows(1)
    Sheets("Pollen").Columns(1).Copy .Columns(1)
    For i = 1 To nDays
        For j = 1 To nYear
        .Cells(1 + i, 1 + j).value = tabSf(i, j)
        Next
    Next
    End With
End Sub
Private Function ComputeR2()
    Dim k As Integer
    Dim varTot As Double
    Dim varExpl As Double
    For k = 1 To 6
        varTot = varTot + coefR2(k) * tabVarObs(k)
        varExpl = varExpl + coefR2(k) * (tabVarObs(k) - tabVarRes(k))
    Next
    ComputeR2 = varExpl / varTot
End Function
Private Function ComputeDF(k As Integer, Optional ByVal Fx As Double = 0) As Double
' Calcule les dates de floraison (après avoir modifié les Fx)
' et retourne le R2 [pour la date-clé n°k seulement]
    Dim y As Integer
    Dim j As Integer
    Dim jObs As Integer
    Dim incr As Integer
    If Fx > 0 Then tabFx(k) = Fx Else Fx = tabFx(k)
    tabVarRes(k) = 0
    For y = 1 To nYear
        jObs = tabDFobs(k, y)
        j = jObs
        If j < tabJLD(y) Then j = tabJLD(y)
        If tabSf(j, y) >= Fx Then    ' Jours décroissants
            Do Until tabSf(j, y) < Fx Or j = 1
                j = j - 1
            Loop
            If j > 1 Then j = j + 1
        Else    ' Jours croissants
            Do Until tabSf(j, y) >= Fx Or j >= nDays
                j = j + 1
            Loop
        End If
        tabDFpre(k, y) = j
        tabVarRes(k) = tabVarRes(k) + (jObs - j) ^ 2
    Next
    ComputeDF = 1 - tabVarRes(k) / tabVarObs(k)
End Function
Private Sub AjustFx()
' Calcule les seuils F* optimaux et les dates prévues
    Dim y As Integer
    Dim j As Integer
    Dim k As Integer
    Dim n As Integer
    Dim Fx As Double
    Dim FxTry As Double
    Dim FxMin As Double
    Dim FxMax As Double
    Dim R2 As Double
    Dim R2Opt As Double
    Dim kF As Double
    Dim kkF As Double
    FxMax = -1E+24: FxMin = 1E+24
    For k = 1 To 6  ' Seuils min et max observés
        For y = 1 To nYear
            Fx = tabSf(tabDFobs(k, y), y)
            If Fx < FxMin Then FxMin = Fx
            If Fx > FxMax Then FxMax = Fx
        Next
    Next
    If FxMin = 0 Then
        If FxMax = 0 Then GoTo END_ERR _
        Else FxMin = FxMax / nValGlo
    End If
    kF = (FxMax / FxMin) ^ (1 / nValGlo)  ' Progression géométrique
    Fx = FxMin
    k = 1
    Do  ' On parcour Fx de Min à Max en ajustant successivement les F(k)
        FxTry = Fx
        R2Opt = ComputeDF(k, FxTry)
        n = 0
        Do  ' Recherche globale : on parcour les valeurs de Fx jusq'à ce que le R² baisse nConf fois de suite
            FxTry = FxTry * kF
            R2 = ComputeDF(k, FxTry)
            If R2 >= R2Opt Then
                Fx = FxTry
                R2Opt = R2
                n = 0
            Else
                n = n + 1
            End If
        Loop Until n = nValConf Or FxTry > FxMax
        FxTry = Fx / kF
        kkF = kF ^ (2 / nValLoc)
        R2 = ComputeDF(k, FxTry)
        For n = 1 To nValLoc + 1 ' Recherche locale : on prend la meilleure les nLoc valeurs dans un intervalle de +/- dF
            FxTry = FxTry * kkF
            R2 = ComputeDF(k, FxTry)
            If R2 >= R2Opt Then
                Fx = FxTry
                R2Opt = R2
            End If
        Next
        ComputeDF k, Fx
        k = k + 1
    Loop Until k > 6
    GoTo END_SUB
END_ERR:  If DBG0 Then msgbox "Pas de valeurs admissibles de F* (min=max=0) !"
    For k = 1 To 6
        ComputeDF k, 0
    Next
END_SUB:
End Sub
Private Sub ReadFx()
' Lit les seuils F* et calcule les dates prévues
    Dim k As Integer
    Dim Fx As Double
    For k = 1 To 6
        Fx = Sheets("Model").Cells(firstDateRow - 2, firstPrevCol + k - 1).value
        ComputeDF k, Fx
    Next
End Sub
