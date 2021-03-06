require 'test_helper'

class AlephItemTest < ActiveSupport::TestCase
  setup do
    @AlephTester = AlephItem.new
    VCR.use_cassette('realtime aleph volume') do
      @item = @AlephTester.xml_status('MIT01001019412').xpath('//items').children.first
    end
  end

  test 'status_url' do
    assert_equal(
      AlephItem.new.status_url('MIT01001739356'),
      'https://fake_server.example.com/rest-dlf/record/MIT01001739356/'\
      'items?view=full&key=FAKE_KEY'
    )
  end

  test 'can return realtime status for an aleph id' do
    VCR.use_cassette('realtime aleph') do
      status = AlephItem.new.items('MIT01001739356', '123456789', 'true')
      assert_equal('Hayden Library', status[0][:library])
      assert_equal('Stacks', status[0][:collection])
      assert_equal('PN1995.9.M86 M855 2010', status[0][:call_number])
      assert_equal(true, status[0][:available?])
      assert_equal('Available - In Library', status[0][:label])
      assert_equal('', status[0][:description])
    end
  end

  test 'can identify non available items' do
    VCR.use_cassette('realtime aleph unavailable') do
      status = AlephItem.new.items('MIT01002511337', '123456789', 'true')
      assert_equal('Rotch Library', status[5][:library])
      assert_equal('Service Desk', status[5][:collection])
      assert_equal('QA27.5.L44 2016a', status[5][:call_number])
      assert_equal(false, status[5][:available?])
      assert_equal('Not available - 03/02/2017 11:59 PM', status[5][:label])
      assert_equal('', status[5][:description])
    end
  end

  test 'adds volume when available' do
    VCR.use_cassette('realtime aleph volume') do
      status = AlephItem.new.items('MIT01001019412', '123456789', 'true')
      assert_equal('Hayden Library', status[0][:library])
      assert_equal('Stacks', status[0][:collection])
      assert_equal('PS3515.U274 2001', status[0][:call_number])
      assert_equal(true, status[0][:available?])
      assert_equal('Available - In Library', status[0][:label])
      assert_equal('v.16', status[0][:description])
    end
  end

  test 'orders volumes in decending order' do
    VCR.use_cassette('redefining realness') do
      status = AlephItem.new.items('MIT01002415590', '123456789', 'true')
      assert_equal('Barker Library', status[0][:library])
      assert_equal('Dewey Library', status[1][:library])
      assert_equal('Hayden Library', status[2][:library])
      assert_equal('Lewis Music Library', status[3][:library])
      assert_equal('Rotch Library', status[4][:library])
    end
  end

  test 'orders libraries in alphabetical order' do
    VCR.use_cassette('realtime aleph volume') do
      status = AlephItem.new.items('MIT01001019412', '123456789', 'true')
      assert_equal('v.1', status[15][:description])
      assert_equal('v.16', status[0][:description])
    end
  end

  # naive sorting of strings will cause an order such as v.1 v.10 v.2
  # this test confirms we are sorting based on integer logic and not
  # string logic
  test 'volumes with multiple digits sort by integer' do
    VCR.use_cassette('volumes with multiple digits') do
      status = AlephItem.new.items('MIT01000009192', '123456789', 'true')
      # .reverse because we used to sort ascending and this was the easiest
      # way to fix the test.
      assert_equal(['v.1', 'v.2', 'v.3', 'v.4', 'v.5', 'v.6', 'v.7', 'v.8',
                    'v.9', 'v.10', 'v.11', 'v.12', 'v.13', 'v.14', 'v.16',
                    'v.17', 'v.18', 'v.19', 'v.20', 'v.21', 'v.22',
                    'v.24'].reverse,
                   status.map { |x| x[:description] })
    end
  end

  test 'description' do
    assert_equal('v.16', @AlephTester.description(@item))
  end

  test 'label' do
    assert_equal('Available - In Library', @AlephTester.label(@item))
  end

  test 'library' do
    assert_equal('Hayden Library', @AlephTester.library(@item))
  end

  test 'status' do
    assert_equal('In Library', @AlephTester.status(@item))
  end

  test 'does not create bogus item for partial tag' do
    VCR.use_cassette('aleph: egregiously many items',
      allow_playback_repeats: true) do

      status = AlephItem.new.items('MIT01000296523', '02187052', 'false')
      assert_equal status.count, 990
    end
  end

  test 'reserve? for item not on reserve' do
    refute @AlephTester.reserve?(@item)
  end

  test 'reserve? for item on reserve' do
    collection = @item.at('z30/z30-collection')
    collection.content = 'Reserve Stacks'
    assert @AlephTester.reserve?(@item)
  end
end
