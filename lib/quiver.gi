#! @Chapter Quivers

DeclareRepresentation( "IsVertexRep", IsComponentObjectRep,
                       [ "quiver", "number" ] );
DeclareRepresentation( "IsArrowRep", IsComponentObjectRep,
                       [ "quiver", "label", "number", "source", "target" ] );
DeclareRepresentation( "IsCompositePathRep", IsComponentObjectRep,
                       [ "arrows" ] );
DeclareRepresentation( "IsQuiverRep", IsComponentObjectRep,
		       [ "label", "vertices", "arrows", "primitivePaths",
		         "vertices_desc", "arrows_desc"] );

InstallMethod( DecomposeQuiverDescriptionString,
               [ IsString ],
function( string )
  local label, vertices, arrows, i, part, c, errmsg;
  errmsg := function( msg )
    return Concatenation( msg, " at position ", String( i ),
                          " in quiver description string \"",
                          string, "\"" );
  end;
  part := 0; # 000000111111111233333334
             # label(vertices)[arrows]
  label := "";
  vertices := "";
  arrows := "";
  for i in [ 1 .. Length( string ) ] do
    c := string[ i ];
    if c = '(' then
      if part = 0 then
        part := 1;
      else
        Error( errmsg( "Unexpected '('" ) );
      fi;
    elif c = ')' then
      if part = 1 then
        part := 2;
      else
        Error( errmsg( "Unexpected ')'" ) );
      fi;
    elif c = '[' then
      if part = 0 or part = 2 then
        part := 3;
      else
        Error( errmsg( "Unexpected '['" ) );
      fi;
    elif c = ']' then
      if part = 3 then
        part := 4;
      else
        Error( errmsg( "Unexpected ']'" ) );
      fi;
    elif part = 0 then
      Add( label, c );
    elif part = 1 then
      Add( vertices, c );
    elif part = 2 then
      Error( errmsg( "Expected '['" ) );
    elif part = 3 then
      Add( arrows, c );
    elif part = 4 then
      Error( errmsg( "Expected end of string" ) );
    else
      Error( errmsg( "Internal error" ) );
    fi;
  od;
  return [ label, vertices, arrows ];
end );

InstallMethod( ParseStringAsLabel,
               [ IsString ],
function( string )
  local num;
  if Length( string ) = 0 then
    Error( "Empty label" );
  fi;
  num := Int( string );
  if num <> fail then
    return num;
  elif Length( string ) = 1 and IsAlphaChar( string[ 1 ] ) then
    return string[ 1 ];
  else
    return string;
  fi;
end );

InstallMethod( ParseLabelPatternString,
               [ IsString ],
function( string )
  local c, num, i, prefix, num_start;
  if Length( string ) = 0 then
    Error( "Empty label pattern" );
  fi;
  num := Int( string );
  if num <> fail then
    return [ IsInt, num - 1 ];
  fi;
  if Length( string ) = 1 then
    c := string[ 1 ];
    if IsAlphaChar( c ) then
      return [ IsChar, IntChar( c ) - 1 ];
    else
      Error( "One-char label pattern must be letter or digit, not ", c );
    fi;
  fi;
  num_start := fail;
  for i in [ 1 .. Length( string ) ] do
    c := string[ i ];
    if IsDigitChar( c ) or c = '-' then
      num_start := i;
      break;
    fi;
  od;
  num := fail;
  if num_start <> fail then
    prefix := string{ [ 1 .. ( num_start - 1 ) ] };
    num := Int( string{ [ num_start .. Length( string ) ] } );
  fi;
  if num = fail then
    Error( "Bad string label pattern \"", string, "\": does not end with an integer" );
  fi;
  return [ IsString, num - 1, prefix ];
end );  

InstallMethod( ApplyLabelPattern,
               [ IsDenseList, IsPosInt ],
function( pattern, i )
  local type, init, num;
  type := pattern[ 1 ];
  init := pattern[ 2 ];
  num := init + i;
  if type = IsInt then
    return num;
  elif type = IsChar then
    if num > 255 or not IsAlphaChar( CharInt( num ) ) then
      Error( "Too high value (", i, ") for character label pattern ", pattern );
    fi;
    return CharInt( num );
  elif type = IsString then
    return Concatenation( pattern[ 3 ], String( num ) );
  else
    Error( "Bad label pattern object ", pattern );
  fi;
end );

InstallMethod( ParseQuiverLabelString,
               [ IsString ],
function( string )
  local quiver_label, vertices_str, arrows_str,
        vertices_pattern, arrows_pattern, tmp;
  tmp := DecomposeQuiverDescriptionString( string );
  quiver_label := tmp[ 1 ];
  vertices_str := tmp[ 2 ];
  arrows_str := tmp[ 3 ];
  if vertices_str <> "" then
    vertices_pattern := ParseLabelPatternString( vertices_str );
  else
    vertices_pattern := fail;
  fi;
  if arrows_str <> "" then
    arrows_pattern := ParseLabelPatternString( arrows_str );
  else
    arrows_pattern := fail;
  fi;
  return [ quiver_label, vertices_pattern, arrows_pattern ];
end );

InstallMethod( ParseArrowDescriptionString,
               [ IsString ],
function( string )
  local split, label, source, target, source_int, target_int;
  split := SplitString( string, ":" );
  if Length( split ) = 2 then
    label := ParseStringAsLabel( split[ 1 ] );
    split := SplitStringSubstring( split[ 2 ], "->" );
    if Length( split ) = 2 then
      source := ParseStringAsLabel( split[ 1 ] );
      target := ParseStringAsLabel( split[ 2 ] );
      return [ label, source, target ];
    fi;
  fi;
  Error( "Bad arrow description string \"", string, "\"" );
end );

InstallMethod( ParseVerticesDescriptionString,
               [ IsString ],
function( string )
  local split, patterns, num;
  num := Int( string );
  if num <> fail then
    return num;
  fi;
  split := SplitStringSubstring( string, ".." );
  if Length( split ) = 2 then
    patterns := List( split, ParseLabelPatternString );
    if patterns[ 1 ][ 1 ] = patterns[ 2 ][ 1 ] and
       patterns[ 1 ][ 2 ] <= patterns[ 2 ][ 2 ] and
       ( patterns[ 1 ][ 1 ] <> IsString or ( patterns[ 1 ][ 3 ] = patterns[ 2 ][ 3 ] ) ) then
      num := patterns[ 2 ][ 2 ] - patterns[ 1 ][ 2 ] + 1;
      return List( [ 1 .. num ], i -> ApplyLabelPattern( patterns[ 1 ], i ) );
    fi;
  elif Length( split ) = 1 then
    return List( SplitString( string, "," ), ParseStringAsLabel );
  fi;
  Error( "Bad vertices string \"", string, "\"" );
end );

InstallMethod( ParseQuiverDescriptionString,
               [ IsString ],
function( string )
  local quiver_label, vertices, arrows, tmp;
  tmp := DecomposeQuiverDescriptionString( string );
  quiver_label := tmp[ 1 ];
  vertices := ParseVerticesDescriptionString( tmp[ 2 ] );
  arrows := List( SplitString( tmp[ 3 ], "," ),
                  ParseArrowDescriptionString );
  return [ quiver_label, vertices, arrows ];
end );

InstallMethod( SplitStringSubstring,
               [ IsString, IsString ],
function( string, sep )
  local sep_len, str_len, i, split, start;
  sep_len := Length( sep );
  str_len := Length( string );
  split := [];
  start := 1;
  i := 1;
  while i <= str_len - sep_len + 1 do
    if string{ [ i .. ( i + sep_len - 1 ) ] } = sep then
      Add( split, string{ [ start .. ( i - 1 ) ] } );
      start := i + sep_len;
      i := start;
    else
      i := i + 1;
    fi;
  od;
  Add( split, string{ [ start .. str_len ] } );
  return split;
end );

InstallMethod( MakeQuiver, "for function, string and lists",
               [ IsFunction, IsString, IsDenseList, IsDenseList ],
function( quiverCat, label, vertices_spec, arrows_spec )
    local pathCat, pathFam, quiverFam, vertexType, arrowType, quiverType,
    	  makeVertex, makeArrow,
          num_vertices, vertices, arrows, Q, i, v, a;

    num_vertices := Length( vertices_spec );
    if quiverCat = IsLeftQuiver then
      pathCat := IsLeftPath;
    elif quiverCat = IsRightQuiver then
      pathCat := IsRightPath;
    else
      Error( "First argument to MakeQuiver must be either IsLeftQuiver or IsRightQuiver" );
    fi;
    if num_vertices = 0 then
      Error( "Quiver must have at least one vertex" );
    fi;
    if Length( label ) = 0 then
      Error( "Empty quiver label" );
    fi;

    pathFam := NewFamily( Concatenation( "paths of ", label ) );
    quiverFam := CollectionsFamily( pathFam );

    quiverType := NewType( quiverFam, quiverCat and IsQuiverRep );
    Q := Objectify( quiverType,
                    rec( label := label,
#		         vertices := vertices, arrows := arrows,
			 vertices_desc := vertices_spec,
			 arrows_desc := arrows_spec ) );

    vertexType := NewType( pathFam, IsVertex and IsVertexRep and pathCat );
    makeVertex := function( num, label )
      return Objectify( vertexType,
                        rec( quiver := Q,
                             number := num,
                             label := label ) );
    end;
    vertices := ListN( [ 1 .. num_vertices ], vertices_spec,
                       makeVertex );
    # vertices := [];
    # for i in [ 1 .. Length( vertices_desc ) ] do
    #   v := Objectify( vertexType,
    #                   rec( number := i,
    # 		           label := vertices_desc[ i ] ) );
    #   Add( vertices, v);
    # od;
    Q!.vertices := vertices;

    arrowType := NewType( pathFam, IsArrow and IsArrowRep and pathCat );
    makeArrow := function( num, a )
      if ( not IsList( a ) ) or Length( a ) <> 3 then
        Error( "Bad arrow specification (should be list of length 3): ", a );
      fi;
      if ( not IsPosInt( a[ 2 ] ) ) or a[ 2 ] > num_vertices then
        Error( "Bad arrow specification (source not int in correct range): ", a );
      fi;
      if ( not IsPosInt( a[ 3 ] ) ) or a[ 3 ] > num_vertices then
        Error( "Bad arrow specification (target not int in correct range): ", a );
      fi;
      return Objectify( arrowType,
             		rec( quiver := Q,
			     number := num,
			     label := a[ 1 ],
 			     source := vertices[ a[ 2 ] ],
 			     target := vertices[ a[ 3 ] ] ) );
    end;
    arrows := ListN( [ 1 .. Length( arrows_spec ) ], arrows_spec,
    	      	     makeArrow );
    Q!.arrows := arrows;

    Q!.primitivePaths := Concatenation( vertices, arrows );

    return Q;
end );

InstallMethod( Quiver, "for function, string, and lists",
               [ IsFunction, IsString, IsDenseList, IsDenseList ],
function( quiverCat, label, vertices, arrows )
  local num_for_label, arrow_with_numbers;
  num_for_label := function( label )
    local i;
    for i in [ 1 .. Length( vertices ) ] do
      if vertices[ i ] = label then
        return i;
      fi;
    od;
    if IsPosInt( label ) then
      return label;
    fi;
    Error( "No vertex with label ", label );
  end;
  arrow_with_numbers := function( arrow )
    if ( not IsList( arrow ) ) or Length( arrow ) <> 3 then
      Error( "Bad arrow specification: ", arrow );
    fi;
    return [ arrow[ 1 ], num_for_label( arrow[ 2 ] ), num_for_label( arrow[ 3 ] ) ];
  end;
  return MakeQuiver( quiverCat, label, vertices, List( arrows, arrow_with_numbers ) );
end );
  
InstallMethod( Quiver, "for function, string, positive integer and list",
               [ IsFunction, IsString, IsPosInt, IsDenseList ],
function( quiverCat, label_with_patterns, num_vertices, arrows )
  local label, vertex_label_pattern, arrow_label_pattern, tmp,
        vertices, arrows_with_labels, set_arrow_label;
  tmp := ParseQuiverLabelString( label_with_patterns );
  label := tmp[ 1 ];
  if tmp[ 2 ] <> fail then
    vertex_label_pattern := tmp[ 2 ];
  else
    vertex_label_pattern := [ IsInt, 0 ];
  fi;
  arrow_label_pattern := tmp[ 3 ];
  vertices := List( [ 1 .. num_vertices ],
                    i -> ApplyLabelPattern( vertex_label_pattern, i ) );
  set_arrow_label := function( i, arrow )
    if Length( arrow ) = 3 then
      return arrow;
    elif Length( arrow ) = 2 then
      if arrow_label_pattern = fail then
        Error( "Arrow without label and no arrow label pattern given" );
      fi;
      return [ ApplyLabelPattern( arrow_label_pattern, i ),
               arrow[ 1 ], arrow[ 2 ] ];
    else
      Error( "Bad arrow specification: ", arrow );
    fi;
  end;
  arrows_with_labels := ListN( [ 1 .. Length( arrows ) ], arrows,
                               set_arrow_label );
  return Quiver( quiverCat, label, vertices, arrows_with_labels );
end );

InstallMethod( Quiver, "for function and string",
               [ IsFunction, IsString ],
function( quiverCat, description )
  return CallFuncList( Quiver,
                       Concatenation( [ quiverCat ],
                                      ParseQuiverDescriptionString( description ) ) );
end );

CallFuncList(
function()
  local left_quiver_func, right_quiver_func, filter_lists, fl;
  left_quiver_func := function( arg )
    return CallFuncList( Quiver, Concatenation( [ IsLeftQuiver ], arg ) );
  end;
  right_quiver_func := function( arg )
    return CallFuncList( Quiver, Concatenation( [ IsRightQuiver ], arg ) );
  end;
  filter_lists := [ [ IsString, IsPosInt, IsDenseList ],
                    [ IsString, IsDenseList, IsDenseList ],
                    [ IsString ] ];
  for fl in filter_lists do
    InstallMethod( LeftQuiver, fl, left_quiver_func );
    InstallMethod( RightQuiver, fl, right_quiver_func );
  od;
end, [] );

# InstallMethod( LeftQuiver, "for string, positive integer and list",
#                [ IsString, IsPosInt, IsDenseList ],
# function( label, num_vertices, arrows )
#   return Quiver( IsLeftQuiver, label, num_vertices, arrows );
# end );

# InstallMethod( LeftQuiver, "for string and lists",
#                [ IsString, IsDenseList, IsDenseList ],
# function( label, vertices, arrows )
#   return Quiver( IsLeftQuiver, label, vertices, arrows );
# end );

# InstallMethod( LeftQuiver, "for string",
#                [ IsString ],
# function( label )
#   return Quiver( IsLeftQuiver, label );
# end );

# InstallMethod( RightQuiver, "for string, positive integer and list",
#                [ IsString, IsPosInt, IsDenseList ],
# function( label, num_vertices, arrows )
#   return Quiver( IsRightQuiver, label, num_vertices, arrows );
# end );

# InstallMethod( RightQuiver, "for string and lists",
#                [ IsString, IsDenseList, IsDenseList ],
# function( label, vertices, arrows )
#   return Quiver( IsRightQuiver, label, vertices, arrows );
# end );

# InstallMethod( RightQuiver, "for string",
#                [ IsString ],
# function( label )
#   return Quiver( IsRightQuiver, label );
# end );

InstallMethod( QuiverOfPath,
               "for vertex",
	       [ IsVertex and IsVertexRep ],
function( a ) return a!.quiver; end );
InstallMethod( QuiverOfPath,
               "for arrow",
	       [ IsArrow and IsArrowRep ],
function( a ) return a!.quiver; end );
InstallMethod( QuiverOfPath,
               "for composite path",
	       [ IsCompositePath and IsCompositePathRep ],
function( a ) return QuiverOfPath( a!.arrows[1] ); end );

InstallMethod( Source,
               "for vertex",
	       [ IsVertex and IsVertexRep ],
function( v ) return v; end );
InstallMethod( Source,
               "for arrow",
	       [ IsArrow and IsArrowRep ],
function( a ) return a!.source; end );
InstallMethod( Source,
               "for composite path",
	       [ IsCompositePath and IsCompositePathRep ],
function( p )
  return Source( p!.arrows[ 1 ] );
end );

InstallMethod( Target,
               "for vertex",
	       [ IsVertex and IsVertexRep ],
function( v ) return v; end );
InstallMethod( Target,
               "for arrow",
	       [ IsArrow and IsArrowRep ],
function( a ) return a!.target; end );
InstallMethod( Target,
               "for composite path",
	       [ IsCompositePath and IsCompositePathRep ],
function( p )
  return Target( p!.arrows[ Length( p!.arrows ) ] );
end );

InstallMethod( LeftEnd, "for left path", [ IsLeftPath ], Target );
InstallMethod( RightEnd, "for left path", [ IsLeftPath ], Source );
InstallMethod( LeftEnd, "for right path", [ IsRightPath ], Source );
InstallMethod( RightEnd, "for right path", [ IsRightPath ], Target );

InstallMethod( Length,
               "for vertex",
	       [ IsVertex and IsVertexRep ],
function( v ) return 0; end );
InstallMethod( Length,
               "for arrow",
	       [ IsArrow and IsArrowRep ],
function( a ) return 1; end );
InstallMethod( Length,
               "for composite path",
	       [ IsCompositePath and IsCompositePathRep ],
function( p )
  return Length( p!.arrows );
end );

InstallMethod( ArrowList,
               "for vertex",
	       [ IsVertex and IsVertexRep ],
function( v ) return []; end );
InstallMethod( ArrowList,
               "for arrow",
	       [ IsArrow and IsArrowRep ],
function( a ) return [ a ]; end );
InstallMethod( ArrowList,
               "for composite path",
	       [ IsCompositePath and IsCompositePathRep ],
function( p )
  return p!.arrows;
end );

InstallMethod( ArrowListLR, "for left path", [ IsLeftPath ],
function( p )
  return Reversed( ArrowList( p ) );
end );

InstallMethod( ArrowListLR, "for right path", [ IsRightPath ], ArrowList );

InstallMethod( AsList,
               "for vertex",
	       [ IsVertex and IsVertexRep ],
function( v ) return [ v ]; end );
InstallMethod( AsList,
               "for arrow",
	       [ IsArrow and IsArrowRep ],
function( a ) return [ a ]; end );
InstallMethod( AsList,
               "for composite path",
	       [ IsCompositePath and IsCompositePathRep ],
function( p )
  return p!.arrows;
end );

InstallMethod( AsListLR, "for left path", [ IsLeftPath ],
function( p )
  return Reversed( AsList( p ) );
end );

InstallMethod( AsListLR, "for right path", [ IsRightPath ], AsList );

InstallMethod( Label,
               "for vertex",
	       [ IsVertex and IsVertexRep ],
function( v )
  return v!.label;
end );

InstallMethod( Label,
               "for arrow",
	       [ IsArrow and IsArrowRep ],
function( a )
  return a!.label;
end );

InstallGlobalFunction( QPA_LABEL_TO_STRING,
function( label )
  if IsString( label ) then
    return label;
  elif IsChar( label ) then
    return [ label ];
  elif IsList( label ) then
    return JoinStringsWithSeparator( List( label, QPA_LABEL_TO_STRING ),
                                     "x" );
  else
    return String( label );
  fi;
end );

InstallMethod( LabelAsString, "for primitive path",
               [ IsPrimitivePath ],
function( p )
  return QPA_LABEL_TO_STRING( Label( p ) );
end );

InstallMethod( VertexNumber,
               "for vertex",
	       [ IsVertex and IsVertexRep ],
function( v )
  return v!.number;
end );

InstallMethod( ArrowNumber,
               "for arrow",
	       [ IsArrow and IsArrowRep ],
function( a )
  return a!.number;
end );

InstallMethod( Composable,
               "for two paths",
	       [ IsPath, IsPath ],
function( p1, p2 )
  return Target( p1 ) = Source( p2 );
end );

InstallMethod( ComposableLR,
               "for two paths",
	       [ IsPath, IsPath ],
function( p1, p2 )
  return RightEnd( p1 ) = LeftEnd( p2 );
end );

InstallMethod( ComposePaths2,
               "for vertex and path",
	       [ IsVertex, IsPath ],
function( v, p )
  if Composable( v, p ) then
    return p;
  else
    return fail;
  fi;
end );

InstallMethod( ComposePaths2,
               "for path and vertex",
	       [ IsPath, IsVertex ],
function( p, v )
  if Composable( p, v ) then
    return p;
  else
    return fail;
  fi;
end );

InstallMethod( ComposePaths2,
               "for two arrows",
	       [ IsArrow, IsArrow ],
function( a1, a2 )
  if Composable( a1, a2 ) then
    return PathFromArrowList( [ a1, a2 ] );
  else
    return fail;
  fi;
end );

InstallMethod( ComposePaths2,
               "for two nontrivial paths",
	       [ IsNontrivialPath, IsNontrivialPath ],
function( p1, p2 )
  if Composable( p1, p2 ) then
    return PathFromArrowList( Concatenation( ArrowList( p1 ), ArrowList( p2 ) ) );
  else
    return fail;
  fi;
end );

InstallOtherMethod( ComposePaths2,
                    "for path and bool",
                    [ IsPath, IsBool ],
function( p, x )
  if x = fail then
    return fail;
  fi;
  TryNextMethod();
end );

InstallOtherMethod( ComposePaths2,
                    "for bool and path",
                    [ IsBool, IsPath ],
function( x, p )
  if x = fail then
    return fail;
  fi;
  TryNextMethod();
end );

InstallGlobalFunction( ComposePaths,
function( arg )
  local list;
  if Length( arg ) = 1 and IsList( arg[ 1 ] ) then
    list := arg[ 1 ];
  else
    list := arg;
  fi;
  return FoldLeft( list, ComposePaths2 );
end );

InstallGlobalFunction( ComposePathsLR,
function( arg )
  local list;
  if Length( arg ) = 1 and IsList( arg[ 1 ] ) then
    list := arg[ 1 ];
  else
    list := arg;
  fi;
  return FoldLeft( list, \* );
end );

InstallMethod( FoldLeft, "for list and function",
               [ IsList, IsFunction ],
function( list, f )
  local result, i;
  result := list[ 1 ];
  for i in [ 2 .. Length( list ) ] do
    result := f( result, list[ i ] );
  od;
  return result;
end );

#! @Section Composition of paths

#! @BeginChunk PathMultiplication
#! @Description
#!  Compose the paths <A>p1</A> and <A>p2</A> in the multiplication order
#!  of the quiver.
#!  In a left-oriented quiver, we have <C>p * q = ComposePaths( q, p )</C>
#!  for any paths <C>p</C> and <C>q</C>.
#!  In a right-oriented quiver, we have <C>p * q = ComposePaths( p, q )</C>
#!  for any paths <C>p</C> and <C>q</C>.
#! @Returns <C>IsPath</C> or <C>fail</C>
InstallMethod( \*, "for two left paths",
               [ IsLeftPath, IsLeftPath ],
function( p1, p2 )
  return ComposePaths2( p2, p1 );
end );
#! @EndChunk PathMultiplication

InstallMethod( \*, "for two right paths",
               [ IsRightPath, IsRightPath ],
               ComposePaths2 );

InstallOtherMethod( \*, "for path and bool",
                    [ IsPath, IsBool ],
function( p, x )
  if x = fail then
    return fail;
  fi;
  TryNextMethod();
end );

InstallOtherMethod( \*, "for bool and path",
                    [ IsBool, IsPath ],
function( x, p )
  if x = fail then
    return fail;
  fi;
  TryNextMethod();
end );

InstallMethod( PathFromArrowListNC,
               "for list",
               [ IsList ],
function( list )
  local pathType;
  if Length( list ) > 1 then
    if IsLeftPath( list[ 1 ] ) then
      pathType := IsLeftPath;
    else
      pathType := IsRightPath;
    fi;
    return Objectify( NewType( FamilyObj( list[ 1 ] ),
                               pathType and IsCompositePath and IsCompositePathRep ),
                      rec( arrows := list ) );
  elif Length( list ) = 1 then
    return list[ 1 ];
  else
    return fail;
  fi;
end );

InstallMethod( PathFromArrowList, "for list", [ IsList ],
function( list )
  local i;
  for i in [ 1 .. Length( list ) - 1 ] do
    if not Composable( list[ i ], list[ i + 1 ] ) then
      Error( "Arrows ", list[ i ], " and ", list[ i + 1 ], " are not composable" );
    fi;
  od;
  return PathFromArrowListNC( list );
end );

InstallMethod( PathFromArrowListLR, "for list", [ IsList ],
function( list )
  if IsLeftPath( list[ 1 ] ) then
    return PathFromArrowList( Reversed( list ) );
  else
    return PathFromArrowList( list );
  fi;
end );

InstallMethod( Subpath, "for vertex and integers",
               [ IsVertex, IsInt, IsInt ],
function( v, from, to )
  if from = 0 and to = 0 then
    return v;
  else
    Error( "Bad bounds (", from, ", ", to, ") for subpath of vertex" );
  fi;
end );

InstallMethod( Subpath, "for arrow and integers",
               [ IsArrow, IsInt, IsInt ],
function( a, from, to )
  if from = 0 and to = 0 then
    return Source( a );
  elif from = 0 and to = 1 then
    return a;
  elif from = 1 and to = 1 then
    return Target( a );
  else
    Error( "Bad bounds (", from, ", ", to, ") for subpath of arrow" );
  fi;
end );

InstallMethod( Subpath, "for composite path and integers",
               [ IsCompositePath, IsInt, IsInt ],
function( p, from, to )
  local list, len;
  list := ArrowList( p );
  len := Length( list );
  if from < 0 or to < from or to > len then
    Error( "Bad bounds (", from, ", ", to, ") ",
           "for subpath of path ", p );
  fi;    
  if from = to then
    if from = 0 then
      return Source( p );
    else
      return Target( list[ from ] );
    fi;
  else
    return PathFromArrowList( list{ [ ( from + 1 ) .. to ] } );
  fi;
end );

InstallMethod( SubpathLR, "for left path and integers",
               [ IsLeftPath, IsInt, IsInt ],
function( p, from, to )
  local len;
  len := Length( p );
  return Subpath( p, len - to, len - from );
end );

InstallMethod( SubpathLR, "for right path and integers",
               [ IsRightPath, IsInt, IsInt ],
               Subpath );

InstallMethod( \<, "for paths",
               IsIdenticalObj,
               [ IsPath, IsPath ],
function( p1, p2 )
  local a1, a2, i;
  if Length( p1 ) < Length( p2 ) then
    return true;
  elif Length( p1 ) > Length( p2 ) then
    return false;
  elif IsVertex( p1 ) then
    return VertexNumber( p1 ) < VertexNumber( p2 );
  elif IsArrow( p1 ) then
    return ArrowNumber( p1 ) < ArrowNumber( p2 );
  else
    a1 := ArrowListLR( p1 );
    a2 := ArrowListLR( p2 );
    for i in [ 1 .. Length( a1 ) ] do
      if a1[ i ] < a2[ i ] then
        return true;
      elif a1[ i ] > a2[ i ] then
        return false;
      fi;
    od;
    return false;
  fi;
end );

InstallMethod( SubpathIndex, "for two vertices",
               IsIdenticalObj,
               [ IsVertex, IsVertex ],
function( v1, v2 )
  if v1 = v2 then
    return 0;
  else
    return fail;
  fi;
end );

InstallMethod( SubpathIndex, "for vertex and nontrivial path",
               IsIdenticalObj,
               [ IsVertex, IsNontrivialPath ],
               ReturnFail );

InstallMethod( SubpathIndex, "for nontrivial path and vertex",
               IsIdenticalObj,
               [ IsNontrivialPath, IsVertex ],
function( p, v )
  local a, i, list;
  if Source( p ) = v then
    return 0;
  fi;
  list := ArrowList( p );
  for i in [ 1 .. Length( list ) ] do
    a := list[ i ];
    if Target( a ) = v then
      return i;
    fi;
  od;
  return fail;
end );

InstallMethod( SubpathIndex, "for two nontrivial paths",
               IsIdenticalObj,
               [ IsNontrivialPath, IsNontrivialPath ],
function( p, q )
  local i, j, list_p, list_q, len_p, len_q, match,
        arrows_left, arrows_right, left, right;
  list_p := ArrowList( p );
  list_q := ArrowList( q );
  len_p := Length( list_p );
  len_q := Length( list_q );
  if len_q > len_p then
    return fail;
  fi;
  for i in [ 1 .. ( len_p - len_q + 1 ) ] do
    match := true;
    for j in [ 1 .. len_q ] do
      if list_p[ i + j - 1 ] <> list_q[ j ] then
        match := false;
        break;
      fi;
    od;
    if match then
      return i - 1;
    fi;
  od;
  return fail;
end );

InstallMethod( SubpathIndexLR, "for left paths",
               [ IsLeftPath, IsLeftPath ],
function( p, q )
  local index;
  index := SubpathIndex( p, q );
  if index = fail then
    return fail;
  else
    return Length( p ) - ( index + Length( q ) );
  fi;
end );

InstallMethod( SubpathIndexLR, "for right paths",
               [ IsRightPath, IsRightPath ],
               SubpathIndex );

InstallMethod( ExtractSubpath, "for two paths",
               [ IsPath, IsPath ],
function( p, q )
  local index;
  index := SubpathIndex( p, q );
  if index = fail then
    return fail;
  else
    return [ Subpath( p, 0, index ),
             Subpath( p, index + Length( q ), Length( p ) ) ];
  fi;
end );

InstallMethod( \/, "for left paths",
               [ IsLeftPath, IsLeftPath ],
function( p, q )
  local quotients;
  quotients := ExtractSubpath( p, q );
  if quotients = fail then
    return fail;
  else
    return [ quotients[ 2 ], quotients[ 1 ] ];
  fi;
end );

InstallMethod( \/, "for right paths",
               [ IsRightPath, IsRightPath ],
               ExtractSubpath );

InstallMethod( PathOverlaps, "for vertex and path",
               [ IsVertex, IsPath ],
function( v, p )
  return [];
end );

InstallMethod( PathOverlaps, "for path and vertex",
               [ IsPath, IsVertex ],
function( p, v )
  return [];
end );

InstallMethod( PathOverlaps, "for two nontrivial paths",
               [ IsNontrivialPath, IsNontrivialPath ],
function( p, q )
  local list_p, list_q, len_p, len_q, overlaps, overlap_len,
        is_overlap, i, b, c;
  list_p := ArrowListLR( p );
  list_q := ArrowListLR( q );
  len_p := Length( list_p );
  len_q := Length( list_q );
  overlaps := [];
  for overlap_len in [ 1 .. Minimum( len_p, len_q ) ] do
    is_overlap := true;
    for i in [ 1 .. overlap_len ] do
      if list_q[ i ] <> list_p[ len_p - overlap_len + i ] then
        is_overlap := false;
        break;
      fi;
    od;
    if is_overlap then
      # find b and c such that p*c = b*q:
      b := SubpathLR( p, 0, len_p - overlap_len );
      c := SubpathLR( q, overlap_len, len_q );
      Add( overlaps, [ b, c ] );
    fi;
  od;
  return overlaps;
end );



InstallMethod( Vertices,
               "for quiver",
	       [ IsQuiver and IsQuiverRep ],
function( Q )
  return Q!.vertices;
end );

InstallMethod( Arrows,
               "for quiver",
	       [ IsQuiver and IsQuiverRep ],
function( Q )
  return Q!.arrows;
end );

InstallMethod( NumberOfVertices,
               "for quiver",
	       [ IsQuiver and IsQuiverRep ],
function( Q )
  return Length( Q!.vertices );
end );

InstallMethod( NumberOfArrows,
               "for quiver",
	       [ IsQuiver and IsQuiverRep ],
function( Q )
  return Length( Q!.arrows );
end );

InstallMethod( PrimitivePaths,
               "for quiver",
	       [ IsQuiver and IsQuiverRep ],
function( Q )
  return Q!.primitivePaths;
end );

InstallMethod( Vertex, "for quiver and positive integer",
	       [ IsQuiver and IsQuiverRep, IsPosInt ],
function( Q, i )
  return Q!.vertices[ i ];
end );

InstallMethod( Arrow, "for quiver and positive integer",
	       [ IsQuiver and IsQuiverRep, IsPosInt ],
function( Q, i )
  return Q!.arrows[ i ];
end );

InstallMethod( PrimitivePathByLabel, "for quiver and object",
               [ IsQuiver, IsObject ],
function( Q, label )
  local p;
  for p in PrimitivePaths( Q ) do
    if Label( p ) = label then
      return p;
    fi;
  od;
  return fail;
end );

InstallMethod( \[\], "for quiver and object",
	       [ IsQuiver, IsObject ],
function( Q, label )
  return PrimitivePathByLabel( Q, label );
end );

InstallMethod( \^, "for quiver and object",
	       [ IsQuiver, IsObject ],
	       PrimitivePathByLabel );

InstallMethod( PathFromString, "for quiver and string",
	       [ IsQuiver, IsString ],
function( Q, string )
  local p, list;
  p := PrimitivePathByLabel( Q, string );
  if p <> fail then
    return p;
  fi;
  list := List( string, label -> PrimitivePathByLabel( Q, label ) );
  if ForAll( list, p -> p <> fail ) then
    return ComposePathsLR( list );
  fi;
  for p in PrimitivePaths( Q ) do
    if LabelAsString( p ) = string then
      return p;
    fi;
  od;
  return fail;
end );

InstallMethod( \., "for quiver and positive integer",
	       [ IsQuiver, IsPosInt ],
function( Q, string_as_int )
  return PathFromString( Q, NameRNam( string_as_int ) );
end );

InstallMethod( String, "for vertex",
               [ IsVertex ],
               LabelAsString );

InstallMethod( ViewObj,
               "for vertex",
	       [ IsVertex ],
function( v )
  Print( "(", String( v ), ")" );
end );

InstallMethod( PrintObj,
               "for vertex",
	       [ IsVertex and IsVertexRep ],
function( v )
  Print( "<vertex ", Label( v ), " in ", Label( QuiverOfPath( v ) ), ">" );
end );

InstallMethod( String, "for arrow",
               [ IsArrow ],
function( a )
  return Concatenation( LabelAsString( a ), ":",
                        String( Source( a ) ), "->",
                        String( Target( a ) ) );
end );

InstallMethod( ViewObj,
               "for arrow",
	       [ IsArrow and IsArrowRep ],
function( a )
#  Print( "(", [Label( a )], ": ", VertexNumber( Source( a ) ), " -> ", VertexNumber( Target( a ) ), ")" );
  Print( "(", String( a ), ")" );
end );

InstallMethod( PrintObj,
               "for arrow",
	       [ IsArrow and IsArrowRep ],
function( a )
  Print( "<arrow ", String( a ),
         " in ", Label( QuiverOfPath( a ) ), ">" );
end );

InstallMethod( PrintObj,
               "for composite path",
	       [ IsCompositePath and IsCompositePathRep ],
function( p )
  Print( "(",
         Iterated( List( ArrowListLR( p ), LabelAsString ),
                   function( a1, a2 ) return Concatenation( a1, "*", a2 ); end ),
         ")" );
end );

InstallMethod( String, "for quiver",
               [ IsQuiver ],
function( Q )
  local vertices, arrows;
  if ForAll( Vertices( Q ),
             v -> Label( v ) = VertexNumber( v ) ) then
    vertices := String( NumberOfVertices( Q ) );
  else
    vertices := JoinStringsWithSeparator( Vertices( Q ), "," );
  fi;
  arrows := JoinStringsWithSeparator( Arrows( Q ), "," );
  return Concatenation( Label( Q ), "(", vertices, ")[", arrows, "]" );
end );

InstallMethod( PrintObj,
               "for quiver",
	       [ IsQuiver ],
function( Q )
  Print( String( Q ) );
end );

InstallMethod( Label,
	       "for quiver",
	       [ IsQuiver and IsQuiverRep ],
function( Q )
  return Q!.label;
end );

InstallMethod( \=,
               "for vertices",
 	       [ IsVertex and IsVertexRep, IsVertex and IsVertexRep ],
	       IsIdenticalObj );
InstallMethod( \=,
               "for arrows",
 	       [ IsArrow and IsArrowRep, IsArrow and IsArrowRep ],
	       IsIdenticalObj );
InstallMethod( \=,
               "for vertex and nontrivial path",
 	       [ IsVertex, IsNontrivialPath ],
	       ReturnFalse );
InstallMethod( \=,
               "for nontrivial path and vertex",
 	       [ IsNontrivialPath, IsVertex ],
	       ReturnFalse );
InstallMethod( \=,
               "for arrow and composite path",
 	       [ IsArrow, IsCompositePath ],
	       ReturnFalse );
InstallMethod( \=,
               "for composite path and arrow",
 	       [ IsCompositePath, IsArrow ],
	       ReturnFalse );
InstallMethod( \=,
	       "for composite paths",
	       [ IsCompositePath, IsCompositePath ],
function( p1, p2 )
  return ArrowList( p1 ) = ArrowList( p2 );
end );

InstallMethod( \in, "for object and quiver",
               [ IsObject, IsQuiver ],
               ReturnFalse );

InstallMethod( \in, "for path and quiver",
               IsElmsColls,
               [ IsPath, IsQuiver ],
               ReturnTrue );