import React, { Component } from 'react';
import './App.css';
import Request from 'react-http-request';
import { Button } from 'reactstrap';

// Displays available polls for voting
export default class App extends Component {

  // votes on a poll
  vote(option, id) {
    var url = 'http://localhost:8090/polls/vote/' + id + '/' + option;

    fetch(url, {
      method: 'POST',
      headers: {}
    })
  }

  render() {

    return (
      <Request
        url='http://localhost:8090/polls/list'
        method='get'
        accept='application/json'
        verbose={true}
      >
        {
          ({error, result, loading}) => {
            if (loading) {
              return <div>loading...</div>;
            } else {
              var fullResponse = JSON.parse(result.text);
              var polls = fullResponse.polls;

              return (
                <div>
                  {polls.map(function(object, i){
                    return <div>
                        <div>
                          {object.title}
                        </div>
                        <div>
                          <Button color="primary" onClick={() => this.vote(1, object.id)}>{object.option1}</Button>{' '}
                          <Button color="primary" onClick={() => this.vote(2, object.id)}>{object.option2}</Button>
                        </div>
                        <div>
                          Current results: {object.option1}: {object.votes1} {object.option2}: {object.votes2}
                        </div>
                        <hr></hr>
                      </div>
                  }, this)}
                </div>
              );
            }
          }
        }
      </Request>
    );
  }
}
