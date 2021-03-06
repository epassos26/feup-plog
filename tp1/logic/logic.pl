create_board(Board):-
  Board = [
  [null, null, null, null, null, null, null, null, null, null, null], %0
  [null, null, null, null, system0, system3, greenNebula, system2, null, null, null], %1
  [null, null, null, blueNebula, system2, system1, blackHole, system1, system1, system1, null], %2
  [null, null, null, system2, system3, system0, system2, system2, wormhole, system3, null], %3
  [null, null, system3, wormhole, system1, redNebula, system1, blueNebula, system1, null, null], %4
  [null, null, system0, system2, system3, system0, system0, system1, system2, null, null], %5
  [null, space, redNebula, system3, greenNebula, system0, system1, blackHole, system1, null, null], %6
  [null, system3, blackHole, greenNebula, system3, system2, system1, system1, null, null, null], %7
  [space, system1, system3, redNebula, wormhole, system0, system1, system1, null, null, null], %8
  [space, space, space, system1, blueNebula, system0, system2, null, null, null, null]]. %9

%initializes the data structures needed for the game
create_players(Ships, TradeStations, Colonies, HomeSystems, Wormholes, NumPlayers, NumShipsPerPlayer):-
  Ships = [
  [[3,2], [4,2], [5,1]],
  [[6,8], [7,8], [5,9]]
  ],
  TradeStations = [
  [],
  []
  ],
  Colonies = [
  [],
  []
  ],
  HomeSystems = [
  [[4, 1], [5, 1], [3, 2], [4, 2]],
  [[6, 8], [7, 8], [5, 9], [6, 9]]
  ],
  Wormholes = [
  [8,3],[3,4],[4,8]
  ],
  NumPlayers = 2,
  NumShipsPerPlayer = 3.

initialize(Board, Ships, TradeStations, Colonies, HomeSystems, Wormholes, NumPlayers, NumShipsPerPlayer):-
  create_board(Board),
  create_players(Ships, TradeStations, Colonies, HomeSystems, Wormholes, NumPlayers, NumShipsPerPlayer).


%calculates the points and declares a winner
game_over(Board, TradeStations, Colonies, HomeSystems, NumPlayers):-
  game_over(Board, TradeStations, Colonies, HomeSystems, NumPlayers, 0, 0, 0).

game_over(_Board, _TradeStations, _Colonies, _HomeSystems, NumPlayers, BestPlayerNo, BestPlayerPoints, NumPlayers):-
  ActualPlayerNo is BestPlayerNo + 1,
  write('Player '), write(ActualPlayerNo), write(' won with '), write(BestPlayerPoints), write(' points!'), nl.

game_over(Board, TradeStations, Colonies, HomeSystems, NumPlayers, PlayerNo, PlayerPoints, CurrentPlayer):-
  calculate_points(Board, TradeStations, Colonies, HomeSystems, CurrentPlayer, NewPlayerPoints),
  NewPlayerNo is CurrentPlayer + 1,
  who_has_max(PlayerNo, PlayerPoints, CurrentPlayer, NewPlayerPoints, BestPlayerNo, BestPlayerPoints),
  game_over(Board, TradeStations, Colonies, HomeSystems, NumPlayers, BestPlayerNo, BestPlayerPoints, NewPlayerNo).

%Checks if a ship is adjacent to a wormhole and if the player has chosen the direction of the wormhole
%%is_move_to_wormhole(+ShipPosition, +Direction, +NumTiles, +Wormholes, -InWormhole)
is_move_to_wormhole(ShipPosition, Direction, Wormholes, InWormhole) :-
    update_position(ShipPosition, Direction, 1, NewPosition),
    list_find(Wormholes, NewPosition, 0, InWormhole).

%checks if a move is valid and performs it
move_ship_if_valid(Board, Ships, TradeStations, Colonies, Wormholes, PlayerNo, ShipNo, ShipPosition, Direction, NumTiles, NewShips):-
  is_move_valid(Board, Ships, TradeStations, Colonies, Wormholes, ShipPosition, Direction, NumTiles, NumTiles),
  move_ship(Ships, ShipPosition, PlayerNo, ShipNo, Direction, NumTiles, NewShips).

%changes the position of the piece
change_piece_position(PieceList, PlayerNo, PieceNo, NewPiecePosition, NewPieceList):-
  list_get_nth(PieceList, PlayerNo, PlayerPieces),
  list_replace_nth(PlayerPieces, PieceNo, NewPiecePosition, NewPlayerPieces),
  list_replace_nth(PieceList, PlayerNo, NewPlayerPieces, NewPieceList).

%moves the ship, updating its position on the Ships list
move_ship(Ships, PlayerNo, ShipNo, Direction, NumTiles, NewShips):-
  get_piece_position(Ships, PlayerNo, ShipNo, ShipPosition),
  move_ship(Ships, ShipPosition, PlayerNo, ShipNo, Direction, NumTiles, NewShips).
move_ship(Ships, ShipPosition, PlayerNo, ShipNo, Direction, NumTiles, NewShips):-
  update_position(ShipPosition, Direction, NumTiles, NewShipPosition),
  list_get_nth(Ships, PlayerNo, PlayerShips),
  list_replace_nth(PlayerShips, ShipNo, NewShipPosition, NewPlayerShips),
  list_replace_nth(Ships, PlayerNo, NewPlayerShips, NewShips).

% TotalNumTiles must be bigger than one in order to allow checking for wormholes
is_direction_valid(Board, Ships, TradeStations, Colonies, Wormholes, Position, Direction):-
  is_move_valid(Board, Ships, TradeStations, Colonies, Wormholes, Position, Direction, 1, 0).

%checks if a move is valid, i.e. if the chosen move makes the ship go through/to a passable position
is_move_valid(_Board, _Ships, _TradeStations, _Colonies, _Wormholes, _Position, _Direction, 0, _TotalNumTiles).
is_move_valid(Board, Ships, TradeStations, Colonies, Wormholes, Position, Direction, 1, 1):-
  update_position(Position, Direction, 1, NewPosition),
  get_tile_in_position(Board, NewPosition, Tile), !, % Cut needed in order to prevent backtracking
  is_tile_passable(Tile, Board, Ships, TradeStations, Colonies, Wormholes, NewPosition),
  is_tile_unoccupied(Ships, NewPosition),
  is_tile_unoccupied(TradeStations, NewPosition),
  is_tile_unoccupied(Colonies, NewPosition).

is_move_valid(Board, Ships, TradeStations, Colonies, Wormholes, Position, Direction, NumTiles, TotalNumTiles):-
  update_position(Position, Direction, 1, NewPosition),
  get_tile_in_position(Board, NewPosition, Tile), !, % Cut needed in order to prevent backtracking
  Tile \= wormhole,
  is_tile_passable(Tile, Board, Ships, TradeStations, Colonies, Wormholes, NewPosition),
  is_tile_unoccupied(Ships, NewPosition),
  is_tile_unoccupied(TradeStations, NewPosition),
  is_tile_unoccupied(Colonies, NewPosition),
  NewNumTiles is NumTiles - 1,
  is_move_valid(Board, Ships, TradeStations, Colonies, Wormholes, NewPosition, Direction, NewNumTiles, TotalNumTiles).

%checks if a ship is not cornered
is_ship_movable(Board, Ships, TradeStations, Colonies, Wormholes, Ship):-
  is_direction_valid(Board, Ships, TradeStations, Colonies, Wormholes, Ship, northwest), !,
  is_direction_valid(Board, Ships, TradeStations, Colonies, Wormholes, Ship, northeast), !,
  is_direction_valid(Board, Ships, TradeStations, Colonies, Wormholes, Ship, east), !,
  is_direction_valid(Board, Ships, TradeStations, Colonies, Wormholes, Ship, southeast), !,
  is_direction_valid(Board, Ships, TradeStations, Colonies, Wormholes, Ship, southwest), !,
  is_direction_valid(Board, Ships, TradeStations, Colonies, Wormholes, Ship, west), !.

are_player_ships_movable(_Board, _Ships, _TradeStations, _Colonies, _Wormholes, []).
are_player_ships_movable(Board, Ships, TradeStations, Colonies, Wormholes, [Ship | OtherShips]):-
  is_ship_movable(Board, Ships, TradeStations, Colonies, Wormholes, Ship);
  are_player_ships_movable(Board, Ships, TradeStations, Colonies, Wormholes, OtherShips).

%checks if any of the ships is moveable and if the players still have trade stations and colonies
is_game_over(_Board, [], _TradeStations, _Colonies, _Wormholes).
is_game_over(Board, [PlayerShips | OtherShips], [PlayerTradeStations | OtherTradeStations], [PlayerColonies | OtherColonies], Wormholes):-
  are_player_ships_movable(Board, [PlayerShips | OtherShips], [PlayerTradeStations | OtherTradeStations], [PlayerColonies | OtherColonies], Wormholes, PlayerShips),
  not(player_has_trade_stations(PlayerTradeStations)),
  not(player_has_colonies(PlayerColonies)),
  is_game_over(Board, OtherShips, OtherTradeStations, OtherColonies, Wormholes).

%checks if a player still has colonies or trade stations, depending on what he chose to place
valid_action(colony, Player, _TradeStations, Colonies) :-
  list_get_nth(Colonies, Player, PlayerColonies), !,
  player_has_colonies(PlayerColonies), !.

valid_action(tradeStation, Player, TradeStations, _Colonies) :-
  list_get_nth(TradeStations, Player, PlayerTradeStations), !,
  player_has_trade_stations(PlayerTradeStations), !.

valid_action(_Action, _Player, _TradeStations, _Colonies) :-
  write('Player has no buildings of requested type'), fail.

%places the trade station or colony
perform_action(Ships, PlayerNo, ShipNo, tradeStation, TradeStations, Colonies, NewTradeStations, NewColonies):-
  get_piece_position(Ships, PlayerNo, ShipNo, ShipPosition),
  place_trade_station(PlayerNo, ShipPosition, TradeStations, NewTradeStations),
  NewColonies = Colonies.

perform_action(Ships, PlayerNo, ShipNo, colony, TradeStations, Colonies, NewTradeStations, NewColonies):-
  get_piece_position(Ships, PlayerNo, ShipNo, ShipPosition),
  place_colony(PlayerNo, ShipPosition, Colonies, NewColonies),
  NewTradeStations = TradeStations.

place_trade_station(PlayerNo, ShipPosition, TradeStations, NewTradeStations):-
  list_get_nth(TradeStations, PlayerNo, PlayerTradeStations),
  NewShipPosition = [ShipPosition],
  list_append(PlayerTradeStations, NewShipPosition, NewPlayerTradeStations),
  list_replace_nth(TradeStations,PlayerNo, NewPlayerTradeStations, NewTradeStations).

place_colony(PlayerNo,ShipPosition, Colonies, NewColonies) :-
  list_get_nth(Colonies, PlayerNo, PlayerColonies),
  NewShipPosition = [ShipPosition],
  list_append(PlayerColonies, NewShipPosition, NewPlayerColonies),
  list_replace_nth(Colonies,PlayerNo, NewPlayerColonies, NewColonies).

can_move_through_wormhole(Board, Ships, TradeStations, Colonies, Wormholes, InWormhole):-
  list_delete_nth(Wormholes, InWormhole, OutWormholes),
  can_move_out_of_wormholes(Board, Ships, TradeStations, Colonies, Wormholes, OutWormholes).

can_move_out_of_wormholes(Board, Ships, TradeStations, Colonies, Wormholes, [WormholePosition | _Others]):-
  is_direction_valid(Board, Ships, TradeStations, Colonies, Wormholes, WormholePosition, northwest).
can_move_out_of_wormholes(Board, Ships, TradeStations, Colonies, Wormholes, [WormholePosition | _Others]):-
  is_direction_valid(Board, Ships, TradeStations, Colonies, Wormholes, WormholePosition, northeast).
can_move_out_of_wormholes(Board, Ships, TradeStations, Colonies, Wormholes, [WormholePosition | _Others]):-
  is_direction_valid(Board, Ships, TradeStations, Colonies, Wormholes, WormholePosition, east).
can_move_out_of_wormholes(Board, Ships, TradeStations, Colonies, Wormholes, [WormholePosition | _Others]):-
  is_direction_valid(Board, Ships, TradeStations, Colonies, Wormholes, WormholePosition, southeast).
can_move_out_of_wormholes(Board, Ships, TradeStations, Colonies, Wormholes, [WormholePosition | _Others]):-
  is_direction_valid(Board, Ships, TradeStations, Colonies, Wormholes, WormholePosition, southwest).
can_move_out_of_wormholes(Board, Ships, TradeStations, Colonies, Wormholes, [WormholePosition | _Others]):-
  is_direction_valid(Board, Ships, TradeStations, Colonies, Wormholes, WormholePosition, west).
can_move_out_of_wormholes(Board, Ships, TradeStations, Colonies, Wormholes, [_WormholePosition | Others]):-
  can_move_out_of_wormholes(Board, Ships, TradeStations, Colonies, Wormholes, Others).

%chooses the direction to which the player will move out of the wormhole
move_through_wormhole(Board, Ships, TradeStations, Colonies, Wormholes, _NumPlayers, _NumShipsPerPlayer, CurrentPlayer, ShipNo, _ShipPosition, _Direction, NewShips, InWormhole):-
  display_wormhole_exits(Wormholes, NumWormholes, InWormhole),
  select_wormhole_exit(NumWormholes, InWormhole, SelectedOutWormhole),
  number_to_wormhole(Wormholes,SelectedOutWormhole, OutWormholePosition),
  list_valid_moves(Board, Ships, TradeStations, Colonies, Wormholes, OutWormholePosition, ValidDirections),
  display_ship_direction_info(ShipNo, ValidDirections),
  select_ship_direction(TmpDirection, ValidDirections),
  move_ship(Ships, OutWormholePosition, CurrentPlayer, ShipNo, TmpDirection, 1, NewShips).

move_through_wormhole(Board, Ships, TradeStations, Colonies, Wormholes, NumPlayers, NumShipsPerPlayer, CurrentPlayer, ShipNo, ShipPosition, Direction, NewShips, InWormhole):-
  move_through_wormhole(Board, Ships, TradeStations, Colonies, Wormholes, NumPlayers, NumShipsPerPlayer, CurrentPlayer, ShipNo, ShipPosition, Direction, NewShips, InWormhole).

number_to_wormhole(Wormholes, SelectedOutWormhole, OutWormhole):-
  N is SelectedOutWormhole - 1,
  list_get_nth(Wormholes, N, OutWormhole).

list_valid_moves(Board, Ships, TradeStations, Colonies, Wormholes, PlayerNo, ShipNo, ValidMoves):-
  get_piece_position(Ships, PlayerNo, ShipNo, Position),
  list_valid_moves(Board, Ships, TradeStations, Colonies, Wormholes, Position, ValidMoves).
list_valid_moves(Board, Ships, TradeStations, Colonies, Wormholes, Position, ValidMoves):-
  append_if_direction_is_valid(Board, Ships, TradeStations, Colonies, Wormholes, Position,
  [northwest, northeast, east, southeast, southwest, west],
   ValidMoves), !.
