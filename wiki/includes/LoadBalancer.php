<?php
/**
 *
 * @package MediaWiki
 */

/**
 * Depends on the database object
 */
require_once( 'Database.php' );

# Valid database indexes
# Operation-based indexes
define( 'DB_SLAVE', -1 );     # Read from the slave (or only server)
define( 'DB_MASTER', -2 );    # Write to master (or only server)
define( 'DB_LAST', -3 );     # Whatever database was used last

# Obsolete aliases
define( 'DB_READ', -1 );
define( 'DB_WRITE', -2 );

/**
 * Database load balancing object
 *
 * @todo document
 * @package MediaWiki
 */
class LoadBalancer {
	/* private */ var $mServers, $mConnections, $mLoads, $mGroupLoads;
	/* private */ var $mFailFunction;
	/* private */ var $mForce, $mReadIndex, $mLastIndex;
	/* private */ var $mWaitForFile, $mWaitForPos, $mWaitTimeout;
	/* private */ var $mLaggedSlaveMode;

	function LoadBalancer()
	{
		$this->mServers = array();
		$this->mConnections = array();
		$this->mFailFunction = false;
		$this->mReadIndex = -1;
		$this->mForce = -1;
		$this->mLastIndex = -1;
	}

	function newFromParams( $servers, $failFunction = false, $waitTimeout = 10 )
	{
		$lb = new LoadBalancer;
		$lb->initialise( $servers, $failFunction, $waitTimeout );
		return $lb;
	}

	function initialise( $servers, $failFunction = false, $waitTimeout = 10 )
	{
		$this->mServers = $servers;
		$this->mFailFunction = $failFunction;
		$this->mReadIndex = -1;
		$this->mWriteIndex = -1;
		$this->mForce = -1;
		$this->mConnections = array();
		$this->mLastIndex = 1;
		$this->mLoads = array();
		$this->mWaitForFile = false;
		$this->mWaitForPos = false;
		$this->mWaitTimeout = $waitTimeout;
		$this->mLaggedSlaveMode = false;

		foreach( $servers as $i => $server ) {
			$this->mLoads[$i] = $server['load'];
			if ( isset( $server['groupLoads'] ) ) {
				foreach ( $server['groupLoads'] as $group => $ratio ) {
					if ( !isset( $this->mGroupLoads[$group] ) ) {
						$this->mGroupLoads[$group] = array();
					}
					$this->mGroupLoads[$group][$i] = $ratio;
				}
			}
		}	
	}
	
	/**
	 * Given an array of non-normalised probabilities, this function will select
	 * an element and return the appropriate key
	 */
	function pickRandom( $weights )
	{
		if ( !is_array( $weights ) || count( $weights ) == 0 ) {
			return false;
		}

		$sum = 0;
		foreach ( $weights as $w ) {
			$sum += $w;
		}

		if ( $sum == 0 ) {
			# No loads on any of them
			# Just pick one at random
			foreach ( $weights as $i => $w ) {
				$weights[$i] = 1;
			}
		}
		$max = mt_getrandmax();
		$rand = mt_rand(0, $max) / $max * $sum;
		
		$sum = 0;
		foreach ( $weights as $i => $w ) {
			$sum += $w;
			if ( $sum >= $rand ) {
				break;
			}
		}
		return $i;
	}

	function getRandomNonLagged( $loads ) {
		# Unset excessively lagged servers
		$lags = $this->getLagTimes();
		foreach ( $lags as $i => $lag ) {
			if ( isset( $this->mServers[$i]['max lag'] ) && $lag > $this->mServers[$i]['max lag'] ) {
				unset( $loads[$i] );
			}
		}


		# Find out if all the slaves with non-zero load are lagged
		$sum = 0;
		foreach ( $loads as $load ) {
			$sum += $load;
		}
		if ( $sum == 0 ) {
			# No appropriate DB servers except maybe the master and some slaves with zero load
			# Do NOT use the master
			# Instead, this function will return false, triggering read-only mode, 
			# and a lagged slave will be used instead.
			unset ( $loads[0] );
		}

		if ( count( $loads ) == 0 ) {
			return false;
		}

		wfDebug( var_export( $loads, true ) );

		# Return a random representative of the remainder
		return $this->pickRandom( $loads );
	}


	function getReaderIndex()
	{
		global $wgMaxLag, $wgReadOnly;

		$fname = 'LoadBalancer::getReaderIndex';
		wfProfileIn( $fname );

		$i = false;
		if ( $this->mForce >= 0 ) {
			$i = $this->mForce;
		} else {
			if ( $this->mReadIndex >= 0 ) {
				$i = $this->mReadIndex;
			} else {
				# $loads is $this->mLoads except with elements knocked out if they
				# don't work
				$loads = $this->mLoads;
				$done = false;
				$totalElapsed = 0;
				do {
					if ( $wgReadOnly ) {
						$i = $this->pickRandom( $loads );
					} else {
						$i = $this->getRandomNonLagged( $loads );
						if ( $i === false && count( $loads ) != 0 )  {
							# All slaves lagged. Switch to read-only mode
							$wgReadOnly = wfMsgNoDB( 'readonly_lag' );
							$i = $this->pickRandom( $loads );
						}
					}
					if ( $i !== false ) {
						wfDebug( "Using reader #$i: {$this->mServers[$i]['host']}...\n" );
						$this->openConnection( $i );
						
						if ( !$this->isOpen( $i ) ) {
							wfDebug( "Failed\n" );
							unset( $loads[$i] );
							$sleepTime = 0;
						} else {
							$status = $this->mConnections[$i]->getStatus();
							if ( isset( $this->mServers[$i]['max threads'] ) && 
							  $status['Threads_running'] > $this->mServers[$i]['max threads'] ) 
							{
								# Slave is lagged, wait for a while
								$sleepTime = 5000 * $status['Threads_connected'];

								# If we reach the timeout and exit the loop, don't use it
								$i = false;
							} else {
								$done = true;
								$sleepTime = 0;
							}
						}
					} else {
						$sleepTime = 500000;
					}
					if ( $sleepTime ) {
							$totalElapsed += $sleepTime;
							usleep( $sleepTime );
					}
				} while ( count( $loads ) && !$done && $totalElapsed / 1e6 < $this->mWaitTimeout );

				if ( $i !== false && $this->isOpen( $i ) ) {
					$this->mReadIndex = $i;
				} else {
					$i = false;
				}
			}
		}
		wfProfileOut( $fname );
		return $i;
	}
	
	/**
	 * Get a random server to use in a query group
	 */
	function getGroupIndex( $group ) {
		if ( isset( $this->mGroupLoads[$group] ) ) {
			$i = $this->pickRandom( $this->mGroupLoads[$group] );
		} else {
			$i = false;
		}
		wfDebug( "Query group $group => $i\n" );
		return $i;
	}
	
	/**
	 * Set the master wait position
	 * If a DB_SLAVE connection has been opened already, waits
	 * Otherwise sets a variable telling it to wait if such a connection is opened
	 */
	function waitFor( $file, $pos ) {
		/*
		$fname = 'LoadBalancer::waitFor';
		wfProfileIn( $fname );

		wfDebug( "User master pos: $file $pos\n" );
		$this->mWaitForFile = false;
		$this->mWaitForPos = false;

		if ( count( $this->mServers ) > 1 ) {
			$this->mWaitForFile = $file;
			$this->mWaitForPos = $pos;
			$i = $this->mReadIndex;

			if ( $i > 0 ) {
				if ( !$this->doWait( $i ) ) {
					$this->mServers[$i]['slave pos'] = $this->mConnections[$i]->getSlavePos();
					$this->mLaggedSlaveMode = true;
				}
			} 
		}
		wfProfileOut( $fname );
		*/
	}

	/**
	 * Wait for a given slave to catch up to the master pos stored in $this
	 */
	function doWait( $index ) {
		return true;
		/*
		global $wgMemc;
		
		$retVal = false;

		# Debugging hacks
		if ( isset( $this->mServers[$index]['lagged slave'] ) ) {
			return false;
		} elseif ( isset( $this->mServers[$index]['fake slave'] ) ) {
			return true;
		}

		$key = 'masterpos:' . $index;
		$memcPos = $wgMemc->get( $key );
		if ( $memcPos ) {
			list( $file, $pos ) = explode( ' ', $memcPos );
			# If the saved position is later than the requested position, return now
			if ( $file == $this->mWaitForFile && $this->mWaitForPos <= $pos ) {
				$retVal = true;
			}
		}

		if ( !$retVal && $this->isOpen( $index ) ) {
			$conn =& $this->mConnections[$index];
			wfDebug( "Waiting for slave #$index to catch up...\n" );
			$result = $conn->masterPosWait( $this->mWaitForFile, $this->mWaitForPos, $this->mWaitTimeout );

			if ( $result == -1 || is_null( $result ) ) {
				# Timed out waiting for slave, use master instead
				wfDebug( "Timed out waiting for slave #$index pos {$this->mWaitForFile} {$this->mWaitForPos}\n" );
				$retVal = false;
			} else {
				$retVal = true;
				wfDebug( "Done\n" );
			}
		}
		return $retVal;*/
	}		

	/**
	 * Get a connection by index
	 */
	function &getConnection( $i, $fail = true, $groups = array() )
	{
		$fname = 'LoadBalancer::getConnection';
		wfProfileIn( $fname );
		
		# Query groups
		$groupIndex = false;
		foreach ( $groups as $group ) {
			$groupIndex = $this->getGroupIndex( $group );
			if ( $groupIndex !== false ) {
				$i = $groupIndex;
				break;
			}
		}
		
		# Operation-based index
		if ( $i == DB_SLAVE ) {	
			$i = $this->getReaderIndex();
		} elseif ( $i == DB_MASTER ) {
			$i = $this->getWriterIndex();
		} elseif ( $i == DB_LAST ) {
			# Just use $this->mLastIndex, which should already be set
			$i = $this->mLastIndex;
			if ( $i === -1 ) {
				# Oh dear, not set, best to use the writer for safety
				wfDebug( "Warning: DB_LAST used when there was no previous index\n" );
				$i = $this->getWriterIndex();
			}
		}
		# Now we have an explicit index into the servers array
		$this->openConnection( $i, $fail );
		
		wfProfileOut( $fname );
		return $this->mConnections[$i];
	}

	/**
	 * Open a connection to the server given by the specified index
	 * Index must be an actual index into the array
	 * Returns success
	 * @private
	 */
	function openConnection( $i, $fail = false ) {
		$fname = 'LoadBalancer::openConnection';
		wfProfileIn( $fname );
		$success = true;

		if ( !$this->isOpen( $i ) ) {
			$this->mConnections[$i] = $this->reallyOpenConnection( $this->mServers[$i] );

			if ( $this->isOpen( $i ) && $i != 0 && $this->mWaitForFile ) {
				if ( !$this->doWait( $i ) ) {
					$this->mServers[$i]['slave pos'] = $this->mConnections[$i]->getSlavePos();
					$success = false;
				}
			}
		}
		if ( !$this->isOpen( $i ) ) {
			wfDebug( "Failed to connect to database $i at {$this->mServers[$i]['host']}\n" );
			if ( $fail ) {
				$this->reportConnectionError( $this->mConnections[$i] );
			}
			$this->mConnections[$i] = false;
			$success = false;
		}
		$this->mLastIndex = $i;
		wfProfileOut( $fname );
		return $success;
	}

	/**
	 * Test if the specified index represents an open connection
	 * @private
	 */
	function isOpen( $index ) {
		if( !is_integer( $index ) ) {
			return false;
		}
		if ( array_key_exists( $index, $this->mConnections ) && is_object( $this->mConnections[$index] ) && 
		  $this->mConnections[$index]->isOpen() ) 
		{
			return true;
		} else {
			return false;
		}
	}
	
	/**
	 * Really opens a connection
	 * @private
	 */
	function reallyOpenConnection( &$server ) {
		if( !is_array( $server ) ) {
			wfDebugDieBacktrace( 'You must update your load-balancing configuration. See DefaultSettings.php entry for $wgDBservers.' );
		}
		
		extract( $server );
		# Get class for this database type
		$class = 'Database' . ucfirst( $type );
		if ( !class_exists( $class ) ) {
			require_once( "$class.php" );
		}

		# Create object
		return new $class( $host, $user, $password, $dbname, 1, $flags );
	}
	
	function reportConnectionError( &$conn )
	{
		$fname = 'LoadBalancer::reportConnectionError';
		wfProfileIn( $fname );
		# Prevent infinite recursion
		
		static $reporting = false;
		if ( !$reporting ) {
			$reporting = true;
			if ( !is_object( $conn ) ) {
				$conn = new Database;
			}
			if ( $this->mFailFunction ) {
				$conn->failFunction( $this->mFailFunction );
			} else {
				$conn->failFunction( 'wfEmergencyAbort' );
			}
			$conn->reportConnectionError();
			$reporting = false;
		}
		wfProfileOut( $fname );
	}
	
	function getWriterIndex()
	{
		return 0;
	}

	function force( $i )
	{
		$this->mForce = $i;
	}

	function haveIndex( $i )
	{
		return array_key_exists( $i, $this->mServers );
	}

	/**
	 * Get the number of defined servers (not the number of open connections)
	 */
	function getServerCount() {
		return count( $this->mServers );
	}

	/**
	 * Save master pos to the session and to memcached, if the session exists
	 */
	function saveMasterPos() {
		global $wgSessionStarted;
		if ( $wgSessionStarted && count( $this->mServers ) > 1 ) {
			# If this entire request was served from a slave without opening a connection to the 
			# master (however unlikely that may be), then we can fetch the position from the slave.
			if ( empty( $this->mConnections[0] ) ) {
				$conn =& $this->getConnection( DB_SLAVE );
				list( $file, $pos ) = $conn->getSlavePos();
				wfDebug( "Saving master pos fetched from slave: $file $pos\n" );
			} else {
				$conn =& $this->getConnection( 0 );
				list( $file, $pos ) = $conn->getMasterPos();
				wfDebug( "Saving master pos: $file $pos\n" );
			}
			if ( $file !== false ) {
				$_SESSION['master_log_file'] = $file;
				$_SESSION['master_pos'] = $pos;
			}
		}
	}

	/**
	 * Loads the master pos from the session, waits for it if necessary
	 */
	function loadMasterPos() {
		if ( isset( $_SESSION['master_log_file'] ) && isset( $_SESSION['master_pos'] ) ) {
			$this->waitFor( $_SESSION['master_log_file'], $_SESSION['master_pos'] );
		}
	}

	/**
	 * Close all open connections
	 */
	function closeAll() {
		foreach( $this->mConnections as $i => $conn ) {
			if ( $this->isOpen( $i ) ) {
				// Need to use this syntax because $conn is a copy not a reference
				$this->mConnections[$i]->close();
			}
		}
	}

	function commitAll() {
		foreach( $this->mConnections as $i => $conn ) {
			if ( $this->isOpen( $i ) ) {
				// Need to use this syntax because $conn is a copy not a reference
				$this->mConnections[$i]->immediateCommit();
			}
		}
	}

	function waitTimeout( $value = NULL ) {
		return wfSetVar( $this->mWaitTimeout, $value );
	}

	function getLaggedSlaveMode() {
		return $this->mLaggedSlaveMode;
	}

	function pingAll() {
		$success = true;
		foreach ( $this->mConnections as $i => $conn ) {
			if ( $this->isOpen( $i ) ) {
				if ( !$this->mConnections[$i]->ping() ) {
					$success = false;
				}
			}
		}
		return $success;
	}

	/**
	 * Get the hostname and lag time of the most-lagged slave
	 * This is useful for maintenance scripts that need to throttle their updates
	 */
	function getMaxLag() {
		$maxLag = -1;
		$host = '';
		foreach ( $this->mServers as $i => $conn ) {
			if ( $this->openConnection( $i ) ) {
				$lag = $this->mConnections[$i]->getLag();
				if ( $lag > $maxLag ) {
					$maxLag = $lag;
					$host = $this->mServers[$i]['host'];
				}
			}
		}
		return array( $host, $maxLag );
	}
	
	/**
	 * Get lag time for each DB
	 * Results are cached for a short time in memcached
	 */
	function getLagTimes() {
		$expiry = 5;
		$requestRate = 10;

		global $wgMemc;
		$times = $wgMemc->get( 'lag_times' );
		if ( $times ) {
			# Randomly recache with probability rising over $expiry
			$elapsed = time() - $times['timestamp'];
			$chance = max( 0, ( $expiry - $elapsed ) * $requestRate );
			if ( mt_rand( 0, $chance ) != 0 ) {
				unset( $times['timestamp'] );
				return $times;
			}
		}

		# Cache key missing or expired

		$times = array();
		foreach ( $this->mServers as $i => $conn ) {
			if ( $this->openConnection( $i ) ) {
				$times[$i] = $this->mConnections[$i]->getLag();
			}
		}

		# Add a timestamp key so we know when it was cached
		$times['timestamp'] = time();
		$wgMemc->set( 'lag_times', $times, $expiry );

		# But don't give the timestamp to the caller
		unset($times['timestamp']);
		return $times;
	}
}

?>
