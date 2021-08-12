-- -------------------------------------------------------------------------- --
-- ReactorHelp : ZRRgin05
--
-- ComputerCraft script to regulate BigReactor control rods based on power drain
-- to minimise fuel use.
--
-- -------------------------------------------------------------------------- --
--
-- -------------------------------------------------------------------------- --

-- -------------------------------------------------------------------------- --
--
-- The reactor, adjust name to suit.
--
local reactor = peripheral.wrap( 'BigReactors-Reactor_0' )

-- -------------------------------------------------------------------------- --
--
-- Variables
--
local running = true										-- Loop control
local rodCount = reactor.getNumberOfControlRods()		    -- Number of control rods
local bufferState											-- Energy in the buffer
local fuelAvailable											-- Available fuel
local cntIndex
local cntTarget
local cntSelect 

-- -------------------------------------------------------------------------- --
--
-- Functions
--

--[[
*
* Return a "HH:MM:SS" timestmap
*
]]--
local function showTime()
  local ts = os.time()

  local hh = math.floor( ts )
  ts = math.floor( ( ts - hh ) * ( 60 * 60 ) )

  local mm = math.floor( ts / 60 )
  local ss = ts - ( mm * 60 )

  return io.write( string.format( "%02d:%02d:%02d", hh, mm, ss ) )
end -- showTime

--[[
*
* Return "OFF" or "ON " in Red or Green...
*
]]--
local function showActive()
  if reactor.getActive() then
    term.setTextColor( colors.green ); io.write( "ON"  )
  else
    term.setTextColor( colors.red   ); io.write( "OFF" )
  end
end -- showActive

--[[
*
* Return reaction rate in Red, Green or Orange
*
]]--
local function showReaction()
  local x = reactor.getFuelReactivity()
  if x > 200 then
    if x > 300 then
      term.setTextColor( colors.green  ); io.write( string.format( "%03d%%", x )  )
    else
      term.setTextColor( colors.orange ); io.write( string.format( "%03d%%", x )  )
    end
  else
      term.setTextColor( colors.red    ); io.write( string.format( "%03d%%", x )  )
  end
end -- showActive

--[[
*
* Return the core temperature
*
]]--
local function showTemperature()
  return io.write( string.format( "%d oC", math.floor( math.floor( reactor.getFuelTemperature() * 100 ) / 100 ) ) )
end -- showTemperature 

--[[
*
* Return the output rate in RF/t (with SI prefix, "XXXx") 
*
]]--
local function showPowerRate()
  local z = math.floor( reactor.getEnergyProducedLastTick() * 1000 )
  local y = 1

  --[[
	 1 :              0.999 : 999mRF
	 2 :              9.990 :   9  RF
	 3 :             99.900 :  99  RF
	 4 :            999.000 : 999  RF
	 5 :          9,990.000 :   9 kRF
	 6 :         99,900.000 :  99 k
	 7 :        999,000.000 : 999 k
	 8 :      9,990,000.000 :   9 M
	 9 :     99,900,000.000 :  99 M
	10 :    999,000,000.000 : 999 M
	11 :  9,990,000,000.000 :   9 G
	12 : 99,900,000,000.000 :  99 G
  ]]--
  while z > 999 do
    z = z / 10
    y = y + 1
  end

  if y == 1 then
	--[[ 0-999 m B/t ]]--
    term.setTextColor( colors.lightGray )
    return io.write( string.format( "%3dm", z ) )
  elseif y < 5 then
	--[[ 0-999   B/t ]]--
    term.setTextColor( colors.yellow )
    return io.write( string.format( "%3d ", z ) )
  elseif y < 8 then
	--[[ 0-999 k B/t ]]--
    term.setTextColor( colors.orange )
    return io.write( string.format( "%3dk", z ) )
  elseif y < 11 then
	--[[ 0-999 M B/t ]]--
    term.setTextColor( colors.red )
    return io.write( string.format( "%3dM", z ) )
  else
	--[[ >0    G B/t ]]--
    term.setTextColor( colors.white )
    return io.write( string.format( "%3dG", z ) )
  end
end -- showPowerRate

--[[
*
* Return the control rate
*
]]--
local function showControlRate( x )
  local y = math.floor( x )
  if y == 0 then
    term.setTextColor( colors.lightGray )
  elseif y < 30 then
    term.setTextColor( colors.lightBlue )
  elseif y < 60 then
    term.setTextColor( colors.yellow )
  elseif y < 80 then
    term.setTextColor( colors.orange )
  elseif y < 90 then
    term.setTextColor( colors.red )
  else
    term.setTextColor( colors.white )
  end
  return io.write( string.format( "%3d", y ) )
end -- showControlRate

--[[
*
* Return the fuel burn rate in B/t (with SI prefix)
*
]]--
local function showBurnRate()
  local z = math.floor( reactor.getFuelConsumedLastTick() * 1000 )
  local y = 1

  --[[
	 1 :              0.999 : 999mRF
	 2 :              9.990 :   9  RF
	 3 :             99.900 :  99  RF
	 4 :            999.000 : 999  RF
	 5 :          9,990.000 :   9 kRF
	 6 :         99,900.000 :  99 k
	 7 :        999,000.000 : 999 k
	 8 :      9,990,000.000 :   9 M
	 9 :     99,900,000.000 :  99 M
	10 :    999,000,000.000 : 999 M
	11 :  9,990,000,000.000 :   9 G
	12 : 99,900,000,000.000 :  99 G
  ]]--
  while z > 999 do
    z = z / 10
    y = y + 1
  end

  if y == 1 then
	--[[ 0-999 m RF/t ]]--
    term.setTextColor( colors.lightGray )
    return io.write( string.format( "%3dm", z ) )
  elseif y < 5 then
	--[[ 0-999   RF/t ]]--
    term.setTextColor( colors.yellow )
    return io.write( string.format( "%3d ", z ) )
  elseif y < 8 then
	--[[ 0-999 k RF/t ]]--
    term.setTextColor( colors.orange )
    return io.write( string.format( "%3dk", z ) )
  elseif y < 11 then
	--[[ 0-999 M RF/t ]]--
    term.setTextColor( colors.red )
    return io.write( string.format( "%3dM", z ) )
  else
	--[[ >0    G RF/t ]]--
    term.setTextColor( colors.white )
    return io.write( string.format( "%3dG", z ) )
  end
end -- showBurnRate

--[[
*
* Draw a bar graph of the control factor, x...
*
]]--
local function showControlBar( x )
  local n = math.floor( 30 * ( x / 100 ) )
  local t = ""
  
  for i=0,(n-1) do t = t .. " " end
  term.setBackgroundColor( colors.lightBlue )
  term.setTextColor( colors.lightGray )
  return io.write( t )
end -- showControlBar

--[[
*
* Draw a bar graph of the fuel buffer
*
]]--
local function showFuelBar()
  local n = math.floor( 30 * ( reactor.getFuelAmount() / reactor.getFuelAmountMax() ) )
  local t = ""
  
  for i=0,(n-1) do t = t .. " " end
  term.setBackgroundColor( colors.cyan )
  term.setTextColor( colors.lightGray )
  return io.write( t )
end -- showFuelBar

--[[
*
* Draw a bar graph of the energy buffer
*
]]--
local function showPowerBar()
  local n = math.floor( 30 * ( reactor.getEnergyStored() / 10000000 ) )
  local t = ""
  
  for i=0,(n-1) do t = t .. " " end
  term.setBackgroundColor( colors.blue )
  term.setTextColor( colors.lightGray )
  return io.write( t )
end -- showPowerBar

-- -------------------------------------------------------------------------- --
-- -------------------------------------------------------------------------- --
-- -------------------------------------------------------------------------- --



-- -------------------------------------------------------------------------- --
--
-- Sanity checks...
--
if not term.isColor() then
	term.clear()
	term.setCursorPos(  1,  1 )
    write( "==[ Need Advanced Computer! ]==" )
	running = false
end
if not reactor.getConnected() then
	term.clear()
	term.setBackgroundColor( colors.orange )
	term.setTextColor( colors.red )
	term.setCursorPos(  1,  1 )
    write( "==[ Not Connected to Reactor ]==" )
	term.setBackgroundColor( colors.black )
	term.setTextColor( colors.white )
	running = false
end

-- -------------------------------------------------------------------------- --
--
-- Main loop
--
while running do

	--[[
	*
	* Collect information
	*
	]]--
	bufferState = reactor.getEnergyStored()
	fuelAvailable = reactor.getFuelAmount()

	--[[
	*
 	* Draw the screen.
	*
	]]--
	term.setBackgroundColor( colors.black ); term.clear()
	term.setTextColor( colors.cyan )
	term.setCursorPos(  1,  1 ); write( "==[" )
	term.setCursorPos( 17,  1 ); write( ".:." )
	term.setCursorPos( 30,  1 ); write( "]=====[" )
	term.setCursorPos( 42,  1 ); write( "|" )
	term.setCursorPos( 49,  1 ); write( "]==" )
	term.setCursorPos(  1,  2 ); write( "===================================================" )
	term.setCursorPos(  1, 13 ); write( "==============================================[Q]==" )
	term.setTextColor( colors.white )
	term.setCursorPos(  5,  1 ); write( "ReactorHelp" )
	term.setCursorPos( 21,  1 ); showTime()
	term.setCursorPos(  2,  9 ); write( "Core Temp. " ); showTemperature()
	term.setCursorPos(  2, 10 ); write( "Rod Count  "..rodCount )
	term.setTextColor( colors.lime )
	term.setCursorPos( 11,  4 ); write(          "0%  .    .    .    .    . 100%" )
	term.setCursorPos(  2,  5 ); write( "BUFFER  :                              :    RF/t" )
	term.setCursorPos(  2,  6 ); write( "CONTROL :                              :    %" )
	term.setCursorPos(  2,  7 ); write( "FUEL    :                              :    B/t" )

	-- If we're out of fuel we need to quit
	if fuelAvailable < 1000 then
	  term.setBackgroundColor( colors.red )
	  term.setTextColor( colors.black )
	  term.setCursorPos( 3, 14 )
	  write( "*** Out of Fuel! ***" )
	  term.setBackgroundColor( colors.black )
	  reactor.setActive( false )
	  running = false
	else
	  reactor.setActive( true )
	end

	-- Control is proportional to energy deffecit when we drop below 8MRF.
	cntTarget = 100 - math.floor( 100 * ( bufferState / 10000000 ) )
	cntSelect = ( cntTarget / 100 ) * rodCount
	for cntIndex = 0, rodCount-1  do
	  if cntIndex < cntSelect then
		reactor.setControlRodLevel( cntIndex,   0 )
                term.setCursorPos(  13 + ( cntIndex * 3 ), 11 ); write( " "..cntIndex.. " " )
                term.setCursorPos(  13 + ( cntIndex * 3 ), 12 ); write( " . " )
	  elseif cntSelect <= cntIndex then
		reactor.setControlRodLevel( cntIndex, 100 )
                term.setCursorPos(  13 + ( cntIndex * 3 ), 11 ); write( " "..cntIndex.." " )
                term.setCursorPos(  13 + ( cntIndex * 3 ), 12 ); write( " O " )
	  else
		reactor.setControlRodLevel( cntIndex, cntSelect )
                term.setCursorPos(  13 + ( cntIndex * 3 ), 11 ); write( " "..cntIndex.." " )
                term.setCursorPos(  13 + ( cntIndex * 3 ), 12 ); write( " o " )
	  end
	end
	term.setBackgroundColor( colors.blue )
	term.setTextColor( colors.white )
	term.setCursorPos( 3, 14 )
	write( "*** ["..cntSelect.."] = "..cntTarget.."%***" )
	term.setBackgroundColor( colors.black )

	--[[
	*
	* Draw dynamic stuff.
	*
	]]--
	term.setCursorPos( 38,  1 ); showActive()
	term.setCursorPos( 44,  1 ); showReaction()

	term.setCursorPos( 11,  5 ); showPowerBar(); term.setBackgroundColor( colors.black )
	term.setCursorPos( 42,  5 ); showPowerRate()

	term.setCursorPos( 11,  6 ); showControlBar( cntTarget ); term.setBackgroundColor( colors.black )
	term.setCursorPos( 43,  6 ); showControlRate( cntTarget )

	term.setCursorPos( 11,  7 ); showFuelBar(); term.setBackgroundColor( colors.black )
	term.setCursorPos( 42,  7 ); showBurnRate()

	
	os.startTimer( 1.5 )
    e,k = os.pullEvent()
    if e == "key" and k == keys.q then
	  running = false
	else
	  running = true
	end
end -- main loop

term.setBackgroundColor( colors.black ); term.setTextColor( colors.white ); term.setCursorPos( 1, 15 )

--[[
local isactive = reactor.getActive();
print( isactive );
local buffer = reactor.getEnergyStored()
reactor.setActive(0)
reactor.getNumberOfControlRods()
reactor.setAllControlRodLevels(0)
reactor.setControlRodLevel(0)
reactor.getControlRodLevel(0)
reactor.getFuelTemperature()
reactor.setAllControlRodLevels(0)
]]--